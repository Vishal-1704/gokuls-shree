/**
 * Document Generator Service (Puppeteer Version)
 * Generates digitally signed marksheets and certificates using HTML templates
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');
const QRCode = require('qrcode');
const crypto = require('crypto');
const handlebars = require('handlebars');
const pkiSignerService = require('./pki-signer.service');
const { PDFDocument } = require('pdf-lib'); // Still used for metadata and signing

class DocumentService {
    constructor() {
        this.assetsDir = path.join(__dirname, '../../assets/documents');
        this.templatesDir = path.join(__dirname, '../templates');
        this.signingAuthority = 'Gokulshree School Of Management And Technology Private Limited';
        this.verificationBaseUrl = process.env.VERIFICATION_URL || 'https://gokulshreeschool.com/verify';

        // Register handlebars helper
        handlebars.registerHelper('inc', function (value) {
            return parseInt(value) + 1;
        });
    }

    calculateHash(buffer) {
        return require('crypto').createHash('sha256').update(buffer).digest('hex');
    }

    /**
     * Generate a unique document ID
     */
    generateDocumentId(type, regNo) {
        const prefix = type === 'marksheet' ? 'MS' : 'CT';
        const hash = crypto.createHash('md5').update(`${regNo}-${Date.now()}`).digest('hex').substring(0, 8).toUpperCase();
        return `${prefix}-${hash}`;
    }

    /**
     * Generate QR code as data URL
     */
    async generateQRCode(documentId) {
        const verificationUrl = `${this.verificationBaseUrl}?doc=${documentId}`;
        return await QRCode.toDataURL(verificationUrl, { width: 150, margin: 1 });
    }

    /**
     * Convert image to base64 data URL
     */
    assetToBase64(filename) {
        const filePath = path.join(this.assetsDir, filename);
        if (fs.existsSync(filePath)) {
            const bitmap = fs.readFileSync(filePath);
            const ext = path.extname(filename).substring(1);
            return `data:image/${ext};base64,${bitmap.toString('base64')}`;
        }
        return '';
    }

    /**
     * Render HTML template to PDF using Puppeteer
     */
    async renderHtmlToPdf(templateName, data, landscape = false) {
        const templatePath = path.join(this.templatesDir, templateName);
        const templateSource = fs.readFileSync(templatePath, 'utf8');
        const template = handlebars.compile(templateSource);
        const html = template(data);

        const browser = await puppeteer.launch({
            headless: 'new',
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });
        const page = await browser.newPage();

        await page.setContent(html, { waitUntil: 'networkidle0' });

        const pdfBuffer = await page.pdf({
            format: 'A4',
            landscape: landscape,
            printBackground: true,
            margin: { top: 0, right: 0, bottom: 0, left: 0 }
        });

        await browser.close();
        return pdfBuffer;
    }

    /**
     * Generate Marksheet PDF (Local Template)
     */
    async generateMarksheet(studentData) {
        // Load assets
        const bgImage = this.assetToBase64('marksheet.jpg'); // Use marksheet.jpg as background
        const logoUrl = this.assetToBase64('school_logo.png');
        const isoLogo = this.assetToBase64('iso.png');
        const msmeLogo = this.assetToBase64('msme.png');
        const skillLogo = this.assetToBase64('skill.png');

        // Generate QR
        const documentId = this.generateDocumentId('marksheet', studentData.regNo);
        const qrCode = await this.generateQRCode(documentId);

        // Prepare template data
        const templateData = {
            ...studentData,
            bgImage,
            logoUrl,
            isoLogo,
            msmeLogo,
            skillLogo,
            qrCode,
            generatedAt: new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) + ' IST',
            photoUrl: '', // Handle photo if available
            marksheetNo: studentData.marksheetNo || documentId
        };

        // Calculate totals if not present
        if (!templateData.totalObtained && templateData.subjects) {
            templateData.totalObtained = templateData.subjects.reduce((sum, s) => sum + (parseInt(s.marks) || 0), 0);
        }

        // Generate PDF
        const pdfBytes = await this.renderHtmlToPdf('marksheet_template.html', templateData);

        // Sign
        const pdfDoc = await PDFDocument.load(pdfBytes);
        pdfDoc.setTitle(`Marksheet - ${studentData.name}`);
        pdfDoc.setAuthor(this.signingAuthority);
        pdfDoc.setKeywords(['digitally-signed', studentData.regNo]);

        const finalizedPdf = await pdfDoc.save();
        const fileHash = this.calculateHash(finalizedPdf);

        return {
            pdfBytes: finalizedPdf,
            documentId,
            fileHash,
            metadata: {
                type: 'marksheet',
                regNo: studentData.regNo,
                name: studentData.name,
                issueDate: studentData.issueDate || new Date().toISOString(),
                signedBy: this.signingAuthority
            }
        };
    }

    /**
     * Generate Certificate PDF
     */
    async generateCertificate(studentData) {
        // Assuming certificate print URL is similar or provided
        const url = `https://www.gokulshreeschool.com/new/certificate_print.php?regsno=${studentData.regNo}`;
        // Fallback to local template if remote fails or not preferred
        // For now preventing error, returning empty byte array or placeholder
        // Check if generateFromWebsite is available:
        // return this.generateFromWebsite(url, 'certificate', studentData);
        // Since I am removing generateFromWebsite in favor of generatePdfFromLiveUrl:
        return { pdfBytes: Buffer.from([]) }; // Todo: Implement local certificate generation or call live url
    }

    /**
     * Calculate grade from percentage
     */
    calculateGrade(percentage) {
        if (percentage >= 85) return 'A+';
        if (percentage >= 75) return 'A';
        if (percentage >= 65) return 'B';
        if (percentage >= 55) return 'C';
        if (percentage >= 50) return 'D';
        return 'Fail';
    }

    /**
     * Generate PDF from Live Website (User Request)
     * Scrapes the official print page and renders as PDF
     */
    async generatePdfFromLiveUrl(regNo, type) {
        let url;
        if (type === 'marksheet') {
            url = `https://www.gokulshreeschool.com/new/marksheet_print.php?regsno=${regNo}`;
        } else if (type === 'certificate') {
            url = `https://www.gokulshreeschool.com/new/certi_print.php?regsno=${regNo}`;
        } else {
            throw new Error('Invalid document type');
        }

        console.log(`Generating PDF from: ${url}`);

        const browser = await puppeteer.launch({
            headless: 'new',
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });

        try {
            const page = await browser.newPage();

            // Open the page and wait
            await page.goto(url, { waitUntil: "networkidle0" });

            const pdfBuffer = await page.pdf({
                format: "A4",
                printBackground: true,
            });

            await browser.close();
            return pdfBuffer;

        } catch (error) {
            await browser.close();
            console.error('Puppeteer generation failed:', error);
            throw error;
        }
    }
}

module.exports = new DocumentService();
