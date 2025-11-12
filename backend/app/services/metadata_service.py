"""Service for extracting PDF metadata and generating citations."""

import re
import requests
from typing import Optional, Dict, Any, List
from pypdf import PdfReader
import io
from datetime import datetime

from app.models.metadata import PDFMetadata, Citation


class MetadataService:
    """Service for PDF metadata extraction."""
    
    @staticmethod
    def extract_from_pdf_info(pdf_bytes: bytes, file_name: str, file_id: str) -> PDFMetadata:
        """Extract metadata from PDF document info."""
        try:
            pdf_reader = PdfReader(io.BytesIO(pdf_bytes))
            info = pdf_reader.metadata or {}
            
            # Extract basic metadata
            title = info.get('/Title') or file_name.replace('.pdf', '')
            author_str = info.get('/Author', '')
            authors = [a.strip() for a in author_str.split(',') if a.strip()] if author_str else []
            
            # Try to extract year from creation date
            year = None
            creation_date = info.get('/CreationDate')
            if creation_date:
                year_match = re.search(r'(\d{4})', str(creation_date))
                if year_match:
                    year = int(year_match.group(1))
            
            # Extract keywords
            keywords_str = info.get('/Keywords', '')
            keywords = [k.strip() for k in keywords_str.split(',') if k.strip()] if keywords_str else []
            
            print(f"Extracted PDF info - Title: {title}, Authors: {authors}, Year: {year}")
            
            return PDFMetadata(
                title=title,
                authors=authors,
                publication_year=year,
                keywords=keywords,
                file_id=file_id,
                file_name=file_name,
                file_size=len(pdf_bytes)
            )
        except Exception as e:
            import traceback
            print(f"Error extracting PDF metadata: {e}")
            print(traceback.format_exc())
            # Return minimal metadata on error
            return PDFMetadata(
                title=file_name.replace('.pdf', ''),
                file_id=file_id,
                file_name=file_name,
                file_size=len(pdf_bytes)
            )
    
    @staticmethod
    def extract_from_first_page(pdf_bytes: bytes, file_name: str, file_id: str) -> PDFMetadata:
        """Extract metadata by parsing the first page content."""
        try:
            pdf_reader = PdfReader(io.BytesIO(pdf_bytes))
            if len(pdf_reader.pages) == 0:
                print("PDF has no pages, falling back to PDF info extraction")
                return MetadataService.extract_from_pdf_info(pdf_bytes, file_name, file_id)
            
            first_page_text = pdf_reader.pages[0].extract_text()
            print(f"Extracted first page text (first 200 chars): {first_page_text[:200]}")
            
            # Start with basic metadata
            metadata = MetadataService.extract_from_pdf_info(pdf_bytes, file_name, file_id)
            
            # Try to find DOI
            doi_match = re.search(r'10\.\d{4,}/[^\s]+', first_page_text)
            if doi_match:
                metadata.doi = doi_match.group(0).rstrip('.,;')
                print(f"Found DOI: {metadata.doi}")
            
            # Try to find arXiv ID
            arxiv_match = re.search(r'arXiv:(\d{4}\.\d{4,5})', first_page_text)
            if arxiv_match:
                metadata.arxiv_id = arxiv_match.group(1)
                print(f"Found arXiv ID: {metadata.arxiv_id}")
            
            # Try to find year in first page
            if not metadata.publication_year:
                year_match = re.search(r'\b(19|20)\d{2}\b', first_page_text)
                if year_match:
                    metadata.publication_year = int(year_match.group(0))
                    print(f"Found year from first page: {metadata.publication_year}")
            
            print(f"Final metadata - Title: {metadata.title}, DOI: {metadata.doi}, Year: {metadata.publication_year}")
            return metadata
        except Exception as e:
            import traceback
            print(f"Error extracting from first page: {e}")
            print(traceback.format_exc())
            return MetadataService.extract_from_pdf_info(pdf_bytes, file_name, file_id)


class CitationService:
    """Service for generating citations from various identifiers."""
    
    @staticmethod
    async def fetch_metadata_from_doi(doi: str) -> Optional[PDFMetadata]:
        """Fetch metadata from DOI using CrossRef API."""
        try:
            url = f"https://api.crossref.org/works/{doi}"
            response = requests.get(url, timeout=10)
            if response.status_code != 200:
                return None
            
            data = response.json()['message']
            
            # Extract authors
            authors = []
            for author in data.get('author', []):
                given = author.get('given', '')
                family = author.get('family', '')
                if given and family:
                    authors.append(f"{given} {family}")
                elif family:
                    authors.append(family)
            
            # Extract year
            year = None
            if 'published-print' in data:
                year = data['published-print']['date-parts'][0][0]
            elif 'published-online' in data:
                year = data['published-online']['date-parts'][0][0]
            
            return PDFMetadata(
                title=data.get('title', [''])[0],
                authors=authors,
                publication_year=year,
                journal=data.get('container-title', [''])[0] if data.get('container-title') else None,
                doi=doi,
                volume=data.get('volume'),
                issue=data.get('issue'),
                pages=data.get('page'),
                publisher=data.get('publisher'),
                url=data.get('URL')
            )
        except Exception as e:
            print(f"Error fetching DOI metadata: {e}")
            return None
    
    @staticmethod
    async def fetch_metadata_from_arxiv(arxiv_id: str) -> Optional[PDFMetadata]:
        """Fetch metadata from arXiv ID."""
        try:
            url = f"http://export.arxiv.org/api/query?id_list={arxiv_id}"
            response = requests.get(url, timeout=10)
            if response.status_code != 200:
                return None
            
            # Parse XML response
            import xml.etree.ElementTree as ET
            root = ET.fromstring(response.content)
            
            # Namespace
            ns = {'atom': 'http://www.w3.org/2005/Atom'}
            entry = root.find('atom:entry', ns)
            if entry is None:
                return None
            
            # Extract data
            title = entry.find('atom:title', ns)
            summary = entry.find('atom:summary', ns)
            published = entry.find('atom:published', ns)
            
            authors = []
            for author in entry.findall('atom:author', ns):
                name = author.find('atom:name', ns)
                if name is not None:
                    authors.append(name.text)
            
            year = None
            if published is not None:
                year_match = re.search(r'(\d{4})', published.text)
                if year_match:
                    year = int(year_match.group(1))
            
            return PDFMetadata(
                title=title.text.strip() if title is not None else None,
                authors=authors,
                publication_year=year,
                arxiv_id=arxiv_id,
                abstract=summary.text.strip() if summary is not None else None,
                url=f"https://arxiv.org/abs/{arxiv_id}"
            )
        except Exception as e:
            print(f"Error fetching arXiv metadata: {e}")
            return None
    
    @staticmethod
    async def fetch_metadata_from_isbn(isbn: str) -> Optional[PDFMetadata]:
        """Fetch metadata from ISBN using Open Library API."""
        try:
            # Clean ISBN
            isbn_clean = isbn.replace('-', '').replace(' ', '')
            url = f"https://openlibrary.org/api/books?bibkeys=ISBN:{isbn_clean}&format=json&jscmd=data"
            response = requests.get(url, timeout=10)
            if response.status_code != 200:
                return None
            
            data = response.json()
            key = f"ISBN:{isbn_clean}"
            if key not in data:
                return None
            
            book = data[key]
            
            # Extract authors
            authors = [author['name'] for author in book.get('authors', [])]
            
            # Extract year
            year = None
            if 'publish_date' in book:
                year_match = re.search(r'(\d{4})', book['publish_date'])
                if year_match:
                    year = int(year_match.group(1))
            
            return PDFMetadata(
                title=book.get('title'),
                authors=authors,
                publication_year=year,
                isbn=isbn,
                publisher=book.get('publishers', [{}])[0].get('name') if book.get('publishers') else None,
                url=book.get('url')
            )
        except Exception as e:
            print(f"Error fetching ISBN metadata: {e}")
            return None
    
    @staticmethod
    async def fetch_metadata_from_url(url: str) -> Optional[PDFMetadata]:
        """Fetch metadata from a general URL by scraping."""
        try:
            response = requests.get(url, timeout=10, headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            })
            if response.status_code != 200:
                return None
            
            from bs4 import BeautifulSoup
            soup = BeautifulSoup(response.content, 'lxml')
            
            # Extract title
            title = None
            # Try Open Graph title
            og_title = soup.find('meta', property='og:title')
            if og_title and og_title.get('content'):
                title = og_title['content']
            # Try Twitter title
            elif soup.find('meta', attrs={'name': 'twitter:title'}):
                title = soup.find('meta', attrs={'name': 'twitter:title'})['content']
            # Try regular title tag
            elif soup.find('title'):
                title = soup.find('title').text.strip()
            
            # Extract author
            authors = []
            author_meta = soup.find('meta', attrs={'name': 'author'})
            if author_meta and author_meta.get('content'):
                authors = [author_meta['content']]
            
            # Extract publication date
            year = None
            date_meta = soup.find('meta', property='article:published_time')
            if date_meta and date_meta.get('content'):
                year_match = re.search(r'(\d{4})', date_meta['content'])
                if year_match:
                    year = int(year_match.group(1))
            
            # Extract description/abstract
            abstract = None
            desc_meta = soup.find('meta', attrs={'name': 'description'})
            if desc_meta and desc_meta.get('content'):
                abstract = desc_meta['content']
            elif soup.find('meta', property='og:description'):
                abstract = soup.find('meta', property='og:description')['content']
            
            # Extract site name/publisher
            publisher = None
            site_meta = soup.find('meta', property='og:site_name')
            if site_meta and site_meta.get('content'):
                publisher = site_meta['content']
            
            return PDFMetadata(
                title=title,
                authors=authors,
                publication_year=year,
                abstract=abstract,
                publisher=publisher,
                url=url
            )
        except Exception as e:
            print(f"Error fetching URL metadata: {e}")
            return None
    
    @staticmethod
    async def fetch_metadata_from_pmid(pmid: str) -> Optional[PDFMetadata]:
        """Fetch metadata from PubMed ID."""
        try:
            url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id={pmid}&retmode=json"
            response = requests.get(url, timeout=10)
            if response.status_code != 200:
                return None
            
            data = response.json()
            if 'result' not in data or pmid not in data['result']:
                return None
            
            article = data['result'][pmid]
            
            # Extract authors
            authors = []
            for author in article.get('authors', []):
                authors.append(author.get('name', ''))
            
            # Extract year
            year = None
            pub_date = article.get('pubdate', '')
            year_match = re.search(r'(\d{4})', pub_date)
            if year_match:
                year = int(year_match.group(1))
            
            # Extract DOI
            doi = None
            for article_id in article.get('articleids', []):
                if article_id.get('idtype') == 'doi':
                    doi = article_id.get('value')
                    break
            
            return PDFMetadata(
                title=article.get('title'),
                authors=authors,
                publication_year=year,
                journal=article.get('fulljournalname'),
                doi=doi,
                pmid=pmid,
                volume=article.get('volume'),
                issue=article.get('issue'),
                pages=article.get('pages'),
                url=f"https://pubmed.ncbi.nlm.nih.gov/{pmid}/"
            )
        except Exception as e:
            print(f"Error fetching PMID metadata: {e}")
            return None
    
    @staticmethod
    def generate_citations(metadata: PDFMetadata) -> Citation:
        """Generate citations in multiple formats from metadata."""
        
        # Format authors
        authors_str = ""
        if metadata.authors:
            if len(metadata.authors) == 1:
                authors_str = metadata.authors[0]
            elif len(metadata.authors) == 2:
                authors_str = f"{metadata.authors[0]} & {metadata.authors[1]}"
            else:
                authors_str = f"{metadata.authors[0]} et al."
        
        # APA format
        apa = CitationService._generate_apa(metadata, authors_str)
        
        # MLA format
        mla = CitationService._generate_mla(metadata, authors_str)
        
        # Chicago format
        chicago = CitationService._generate_chicago(metadata, authors_str)
        
        # BibTeX format
        bibtex = CitationService._generate_bibtex(metadata)
        
        return Citation(
            apa=apa,
            mla=mla,
            chicago=chicago,
            bibtex=bibtex,
            metadata=metadata
        )
    
    @staticmethod
    def _generate_apa(metadata: PDFMetadata, authors_str: str) -> str:
        """Generate APA format citation."""
        parts = []
        
        if authors_str:
            parts.append(f"{authors_str}.")
        
        if metadata.publication_year:
            parts.append(f"({metadata.publication_year}).")
        
        if metadata.title:
            parts.append(f"{metadata.title}.")
        
        if metadata.journal:
            journal_part = f"*{metadata.journal}*"
            if metadata.volume:
                journal_part += f", *{metadata.volume}*"
            if metadata.issue:
                journal_part += f"({metadata.issue})"
            if metadata.pages:
                journal_part += f", {metadata.pages}"
            parts.append(journal_part + ".")
        elif metadata.publisher:
            # For web pages without journal
            parts.append(f"*{metadata.publisher}*.")
        
        if metadata.doi:
            parts.append(f"https://doi.org/{metadata.doi}")
        elif metadata.url:
            parts.append(metadata.url)
        
        return " ".join(parts)
    
    @staticmethod
    def _generate_mla(metadata: PDFMetadata, authors_str: str) -> str:
        """Generate MLA format citation."""
        parts = []
        
        if metadata.authors and len(metadata.authors) > 0:
            # Last name, First name format for first author
            first_author = metadata.authors[0]
            name_parts = first_author.split()
            if len(name_parts) >= 2:
                parts.append(f"{name_parts[-1]}, {' '.join(name_parts[:-1])}.")
            else:
                parts.append(f"{first_author}.")
        
        if metadata.title:
            parts.append(f'"{metadata.title}."')
        
        if metadata.journal:
            parts.append(f"*{metadata.journal}*,")
        
        if metadata.volume:
            parts.append(f"vol. {metadata.volume},")
        
        if metadata.issue:
            parts.append(f"no. {metadata.issue},")
        
        if metadata.publication_year:
            parts.append(f"{metadata.publication_year},")
        
        if metadata.pages:
            parts.append(f"pp. {metadata.pages}.")
        
        if metadata.doi:
            parts.append(f"doi:{metadata.doi}.")
        
        return " ".join(parts)
    
    @staticmethod
    def _generate_chicago(metadata: PDFMetadata, authors_str: str) -> str:
        """Generate Chicago format citation."""
        parts = []
        
        if metadata.authors and len(metadata.authors) > 0:
            first_author = metadata.authors[0]
            name_parts = first_author.split()
            if len(name_parts) >= 2:
                parts.append(f"{name_parts[-1]}, {' '.join(name_parts[:-1])}.")
            else:
                parts.append(f"{first_author}.")
        
        if metadata.title:
            parts.append(f'"{metadata.title}."')
        
        if metadata.journal:
            journal_part = f"*{metadata.journal}*"
            if metadata.volume:
                journal_part += f" {metadata.volume}"
            if metadata.issue:
                journal_part += f", no. {metadata.issue}"
            parts.append(journal_part)
        
        if metadata.publication_year:
            parts.append(f"({metadata.publication_year}):")
        
        if metadata.pages:
            parts.append(f"{metadata.pages}.")
        
        if metadata.doi:
            parts.append(f"https://doi.org/{metadata.doi}.")
        
        return " ".join(parts)
    
    @staticmethod
    def _generate_bibtex(metadata: PDFMetadata) -> str:
        """Generate BibTeX format citation."""
        # Generate citation key
        key_parts = []
        if metadata.authors and len(metadata.authors) > 0:
            first_author_last = metadata.authors[0].split()[-1].lower()
            key_parts.append(first_author_last)
        if metadata.publication_year:
            key_parts.append(str(metadata.publication_year))
        
        key = "".join(key_parts) if key_parts else "unknown"
        
        # Determine entry type
        if metadata.journal:
            entry_type = "article"
        elif metadata.url:
            entry_type = "online"
        else:
            entry_type = "misc"
        
        lines = [f"@{entry_type}{{{key},"]
        
        if metadata.title:
            lines.append(f'  title = {{{metadata.title}}},')
        
        if metadata.authors:
            authors_bibtex = " and ".join(metadata.authors)
            lines.append(f'  author = {{{authors_bibtex}}},')
        
        if metadata.journal:
            lines.append(f'  journal = {{{metadata.journal}}},')
        
        if metadata.volume:
            lines.append(f'  volume = {{{metadata.volume}}},')
        
        if metadata.issue:
            lines.append(f'  number = {{{metadata.issue}}},')
        
        if metadata.pages:
            lines.append(f'  pages = {{{metadata.pages}}},')
        
        if metadata.publication_year:
            lines.append(f'  year = {{{metadata.publication_year}}},')
        
        if metadata.doi:
            lines.append(f'  doi = {{{metadata.doi}}},')
        
        if metadata.publisher:
            lines.append(f'  publisher = {{{metadata.publisher}}},')
        
        lines.append("}")
        
        return "\n".join(lines)
