from pathlib import Path
from docx import Document
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,PageBreak
from reportlab.lib.styles import getSampleStyleSheet,ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from xml.sax.saxutils import escape
import pypdfium2 as pdfium
from PIL import Image,ImageOps,ImageDraw
pdfmetrics.registerFont(TTFont('Guide','C:/Windows/Fonts/calibri.ttf'))
pdfmetrics.registerFont(TTFont('GuideBold','C:/Windows/Fonts/calibrib.ttf'))
pdfmetrics.registerFont(TTFont('Code','C:/Windows/Fonts/consola.ttf'))
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='BodyGuide',fontName='Guide',fontSize=10.5,leading=14,spaceAfter=7))
styles.add(ParagraphStyle(name='GuideTitle',fontName='GuideBold',fontSize=25,leading=29,spaceAfter=14))
styles.add(ParagraphStyle(name='GuideH1',fontName='GuideBold',fontSize=18,leading=23,spaceAfter=12))
styles.add(ParagraphStyle(name='GuideH2',fontName='GuideBold',fontSize=12,leading=16,spaceBefore=9,spaceAfter=6,keepWithNext=True))
styles.add(ParagraphStyle(name='GuideCode',fontName='Code',fontSize=8.4,leading=11,spaceAfter=3))
out=Path('output/pdf');out.mkdir(parents=True,exist_ok=True)
flow=[]
for p in Document('docs/ArrowNova-Build-and-Release-Guide.docx').paragraphs:
 if 'w:type="page"' in p._p.xml:
  flow.append(PageBreak());continue
 text=p.text
 if not text: continue
 name=p.style.name
 style='BodyGuide'
 if name=='Title':style='GuideTitle'
 elif name=='Heading 1':style='GuideH1'
 elif name=='Heading 2':style='GuideH2'
 elif p.runs and p.runs[0].font.name=='Consolas':style='GuideCode'
 if name=='List Bullet':text='• '+text
 flow.append(Paragraph(escape(text).replace('\n','<br/>'),styles[style]))
def footer(c,d):
 c.setFont('Guide',8);c.drawString(50,27,'ArrowNova developer guide | 14 October 2026');c.drawRightString(562,27,str(d.page))
f=out/'ArrowNova-Build-and-Release-Guide.pdf'
SimpleDocTemplate(str(f),pagesize=(612,792),leftMargin=50,rightMargin=50,topMargin=42,bottomMargin=42).build(flow,onFirstPage=footer,onLaterPages=footer)
pdf=pdfium.PdfDocument(str(f));thumbs=[]
for i,page in enumerate(pdf):
 pic=out/f'guide-page-{i+1}.png';page.render(scale=1.25).to_pil().save(pic)
 im=Image.open(pic);im.thumbnail((367,475));thumbs.append(im)
sheet=Image.new('RGB',(367*3,495*((len(thumbs)+2)//3)),'#cccccc')
for i,im in enumerate(thumbs):sheet.paste(im,((i%3)*367,(i//3)*495))
sheet.save(out/'guide-contact-sheet.png')
print('PDF pages:',len(pdf))
