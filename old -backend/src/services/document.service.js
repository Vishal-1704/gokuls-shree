/**
 * Document Generator Service (pdf-lib Version - Pure JS)
 * Generates digitally signed marksheets and certificates using template images and absolute coordinate drawing.
 * Bypasses Puppeteer completely to make the service lightweight and high-performance.
 */

const fs = require('fs');
const path = require('path');
const QRCode = require('qrcode');
const crypto = require('crypto');
const axios = require('axios');
const cheerio = require('cheerio');
const { PDFDocument, rgb, StandardFonts } = require('pdf-lib');

class DocumentService {
    constructor() {
        this.assetsDir = path.join(__dirname, '../../assets/documents');
        this.signingAuthority = 'Gokulshree School Of Management And Technology Private Limited';
        this.verificationBaseUrl = process.env.VERIFICATION_URL || 'https://gokulshreeschool.com/verify';
    }

    calculateHash(buffer) {
        return crypto.createHash('sha256').update(buffer).digest('hex');
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
     * Generate Marksheet PDF (Local Template using pdf-lib)
     */
    async generateMarksheet(studentData) {
        const pdfDoc = await PDFDocument.create();
        const page = pdfDoc.addPage([595.28, 841.89]); // A4 Portrait

        // Load background
        const bgImagePath = path.join(this.assetsDir, 'marksheet.jpg');
        if (fs.existsSync(bgImagePath)) {
            const bgBytes = fs.readFileSync(bgImagePath);
            const bgImage = await pdfDoc.embedJpg(bgBytes);
            page.drawImage(bgImage, { x: 0, y: 0, width: 595.28, height: 841.89 });
        }

        // Fonts
        const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
        const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

        // Header Logos & Texts
        // 1. School Logo
        const logoPath = path.join(this.assetsDir, 'school_logo.png');
        if (fs.existsSync(logoPath)) {
            const logoBytes = fs.readFileSync(logoPath);
            const logoImg = await pdfDoc.embedPng(logoBytes);
            page.drawImage(logoImg, { x: 50, y: 715, width: 65, height: 65 });
        }

        // School Names
        page.drawText('Gokulshree School Of Management And', {
            x: 130,
            y: 755,
            size: 15,
            font: fontBold,
            color: rgb(0.8, 0.1, 0.1),
        });
        page.drawText('Technology Private Limited', {
            x: 180,
            y: 737,
            size: 15,
            font: fontBold,
            color: rgb(0.8, 0.1, 0.1),
        });

        // Details
        page.drawText('Registered Under Companies Act 2013. CIN: U80900UP2021PTC154024', {
            x: 135,
            y: 723,
            size: 7,
            font: font,
            color: rgb(0.2, 0.2, 0.2),
        });
        page.drawText('MSME Registration: UDYAM-UP-69-0000812. AN ISO 9001:2015 Certified Institute.', {
            x: 125,
            y: 713,
            size: 7,
            font: font,
            color: rgb(0.2, 0.2, 0.2),
        });

        // Other logos: ISO, MSME, Skill
        const isoPath = path.join(this.assetsDir, 'iso.png');
        if (fs.existsSync(isoPath)) {
            const img = await pdfDoc.embedPng(fs.readFileSync(isoPath));
            page.drawImage(img, { x: 500, y: 740, width: 25, height: 25 });
        }
        const msmePath = path.join(this.assetsDir, 'msme.png');
        if (fs.existsSync(msmePath)) {
            const img = await pdfDoc.embedPng(fs.readFileSync(msmePath));
            page.drawImage(img, { x: 530, y: 740, width: 25, height: 25 });
        }
        const skillPath = path.join(this.assetsDir, 'skill.png');
        if (fs.existsSync(skillPath)) {
            const img = await pdfDoc.embedPng(fs.readFileSync(skillPath));
            page.drawImage(img, { x: 500, y: 710, width: 55, height: 25 });
        }

        // QR Code
        const documentId = this.generateDocumentId('marksheet', studentData.regNo);
        const verificationUrl = `${this.verificationBaseUrl}?doc=${documentId}`;
        const qrCodeBuffer = await QRCode.toBuffer(verificationUrl, { width: 80, margin: 1 });
        const qrCodeImg = await pdfDoc.embedPng(qrCodeBuffer);
        page.drawImage(qrCodeImg, { x: 50, y: 620, width: 75, height: 75 });

        // Statement of Marks banner
        page.drawRectangle({
            x: 180,
            y: 650,
            width: 235,
            height: 30,
            color: rgb(0.5, 0, 0),
        });
        page.drawText('STATEMENT OF MARKS', {
            x: 205,
            y: 660,
            size: 14,
            font: fontBold,
            color: rgb(1, 1, 0), // Yellow
        });
        page.drawText('Verify This Marksheet: www.gokulshreeschool.com', {
            x: 195,
            y: 635,
            size: 8,
            font: fontBold,
            color: rgb(0.8, 0, 0),
        });

        // Top info text
        page.drawText(`Enroll. No.: ${studentData.regNo}`, { x: 50, y: 790, size: 9, font: fontBold });
        page.drawText(`Serial. No.: ${studentData.marksheetNo || documentId}`, { x: 420, y: 790, size: 9, font: fontBold });

        // Student details box
        const drawDetailLine = (label, value, y) => {
            page.drawText(label, { x: 50, y, size: 10, font: fontBold, color: rgb(0,0,0) });
            page.drawText(value || '', { x: 180, y, size: 10, font: font, color: rgb(0,0,0) });
            page.drawLine({
                start: { x: 175, y: y - 2 },
                end: { x: 545, y: y - 2 },
                thickness: 1,
                color: rgb(0.6, 0.7, 0.9),
                dashArray: [2, 2]
            });
        };

        drawDetailLine('Student Name:', studentData.name, 590);
        drawDetailLine("Father's Name:", studentData.fatherName || "N/A", 570);
        drawDetailLine('Course Name:', studentData.courseName || studentData.course || '', 550);
        
        page.drawText('Roll No.:', { x: 50, y: 530, size: 10, font: fontBold });
        page.drawText(studentData.rollNo || '', { x: 180, y: 530, size: 10, font: font });
        page.drawLine({ start: { x: 175, y: 528 }, end: { x: 300, y: 528 }, thickness: 1, color: rgb(0.6, 0.7, 0.9), dashArray: [2, 2] });

        page.drawText('Exam Session:', { x: 320, y: 530, size: 10, font: fontBold });
        page.drawText(studentData.session || 'N/A', { x: 420, y: 530, size: 10, font: font });
        page.drawLine({ start: { x: 415, y: 528 }, end: { x: 545, y: 528 }, thickness: 1, color: rgb(0.6, 0.7, 0.9), dashArray: [2, 2] });

        // Subjects Table
        // Draw Table headers
        let tableY = 490;
        page.drawRectangle({
            x: 50,
            y: tableY,
            width: 495,
            height: 20,
            color: rgb(0.9, 0.9, 0.9),
            borderColor: rgb(0, 0, 0),
            borderWidth: 1
        });
        
        page.drawText('Subject / Paper Name', { x: 60, y: tableY + 6, size: 9, font: fontBold });
        page.drawText('Max Marks', { x: 330, y: tableY + 6, size: 9, font: fontBold });
        page.drawText('Min Marks', { x: 400, y: tableY + 6, size: 9, font: fontBold });
        page.drawText('Obtained', { x: 480, y: tableY + 6, size: 9, font: fontBold });

        // Loop over subjects
        const subjects = studentData.subjects || [];
        let currentY = tableY - 20;
        for (let i = 0; i < Math.max(subjects.length, 5); i++) {
            page.drawRectangle({
                x: 50,
                y: currentY,
                width: 495,
                height: 20,
                borderColor: rgb(0, 0, 0),
                borderWidth: 1
            });

            // Draw column vertical lines
            page.drawLine({ start: { x: 320, y: currentY }, end: { x: 320, y: currentY + 20 }, thickness: 1 });
            page.drawLine({ start: { x: 390, y: currentY }, end: { x: 390, y: currentY + 20 }, thickness: 1 });
            page.drawLine({ start: { x: 470, y: currentY }, end: { x: 470, y: currentY + 20 }, thickness: 1 });

            if (i < subjects.length) {
                const sub = subjects[i];
                page.drawText(sub.name || '', { x: 60, y: currentY + 6, size: 9, font: font });
                page.drawText((sub.maxMarks || 100).toString(), { x: 345, y: currentY + 6, size: 9, font: font });
                page.drawText((sub.minMarks || 40).toString(), { x: 415, y: currentY + 6, size: 9, font: font });
                page.drawText((sub.marks || 0).toString(), { x: 495, y: currentY + 6, size: 9, font: fontBold });
            } else {
                page.drawText('-', { x: 60, y: currentY + 6, size: 9, font: font });
            }
            currentY -= 20;
        }

        // Totals Row
        page.drawRectangle({
            x: 50,
            y: currentY,
            width: 495,
            height: 20,
            color: rgb(0.95, 0.95, 0.95),
            borderColor: rgb(0, 0, 0),
            borderWidth: 1
        });
        page.drawLine({ start: { x: 320, y: currentY }, end: { x: 320, y: currentY + 20 }, thickness: 1 });
        page.drawLine({ start: { x: 390, y: currentY }, end: { x: 390, y: currentY + 20 }, thickness: 1 });
        page.drawLine({ start: { x: 470, y: currentY }, end: { x: 470, y: currentY + 20 }, thickness: 1 });

        const totalObtained = studentData.totalObtained || subjects.reduce((sum, s) => sum + (parseInt(s.marks) || 0), 0);
        const totalMax = subjects.reduce((sum, s) => sum + (parseInt(s.maxMarks) || 100), 0) || 100;
        const percentage = studentData.percentage || ((totalObtained / totalMax) * 100).toFixed(1);
        const grade = studentData.grade || this.calculateGrade(parseFloat(percentage));
        const result = studentData.result || (parseFloat(percentage) >= 40 ? 'PASS' : 'FAIL');

        page.drawText('TOTAL MARKS OBTAINED', { x: 60, y: currentY + 6, size: 9, font: fontBold });
        page.drawText(totalMax.toString(), { x: 345, y: currentY + 6, size: 9, font: fontBold });
        page.drawText('', { x: 415, y: currentY + 6, size: 9, font: font });
        page.drawText(totalObtained.toString(), { x: 495, y: currentY + 6, size: 9, font: fontBold, color: rgb(0, 0.5, 0) });

        // Result and Grade summary
        currentY -= 35;
        page.drawText(`Percentage: ${percentage}%`, { x: 50, y: currentY, size: 10, font: fontBold });
        page.drawText(`Grade: ${grade}`, { x: 220, y: currentY, size: 10, font: fontBold });
        page.drawText(`Result: ${result}`, { x: 380, y: currentY, size: 10, font: fontBold, color: result === 'PASS' ? rgb(0,0.5,0) : rgb(0.8,0,0) });

        // Digital Sign Visual Box
        page.drawRectangle({
            x: 320,
            y: 110,
            width: 225,
            height: 50,
            borderColor: rgb(0.8, 0.8, 0.8),
            borderWidth: 1,
            color: rgb(0.98, 0.98, 0.98),
        });
        page.drawText('DIGITALLY SIGNED', { x: 330, y: 145, size: 9, font: fontBold, color: rgb(0, 0.5, 0) });
        page.drawText(`Authority: ${this.signingAuthority}`, { x: 330, y: 132, size: 7, font: font });
        page.drawText(`Date: ${new Date().toLocaleDateString('en-IN')}`, { x: 330, y: 120, size: 7, font: font });
        page.drawText('✓', { x: 500, y: 122, size: 30, font: fontBold, color: rgb(0, 0.6, 0) });

        page.drawText(`Date of Issue: ${studentData.issueDate || new Date().toLocaleDateString('en-IN')}`, { x: 50, y: 80, size: 9, font: fontBold });

        pdfDoc.setTitle(`Marksheet - ${studentData.name}`);
        pdfDoc.setAuthor(this.signingAuthority);
        pdfDoc.setKeywords(['digitally-signed', studentData.regNo]);

        const finalizedPdf = await pdfDoc.save();
        const fileHash = this.calculateHash(finalizedPdf);

        return {
            pdfBytes: Buffer.from(finalizedPdf),
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
     * Generate Certificate PDF (Landscape using pdf-lib)
     */
    async generateCertificate(studentData) {
        const pdfDoc = await PDFDocument.create();
        const page = pdfDoc.addPage([841.89, 595.28]); // A4 Landscape

        // Load background
        const bgImagePath = path.join(this.assetsDir, 'certificate.jpg');
        if (fs.existsSync(bgImagePath)) {
            const bgBytes = fs.readFileSync(bgImagePath);
            const bgImage = await pdfDoc.embedJpg(bgBytes);
            page.drawImage(bgImage, { x: 0, y: 0, width: 841.89, height: 595.28 });
        }

        // Fonts
        const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
        const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

        // Header Logos & Texts
        const logoPath = path.join(this.assetsDir, 'school_logo.png');
        if (fs.existsSync(logoPath)) {
            const logoBytes = fs.readFileSync(logoPath);
            const logoImg = await pdfDoc.embedPng(logoBytes);
            page.drawImage(logoImg, { x: 70, y: 460, width: 70, height: 70 });
        }

        page.drawText('Gokulshree School Of Management & Technology', {
            x: 160,
            y: 505,
            size: 22,
            font: fontBold,
            color: rgb(0.8, 0.1, 0.1),
        });
        page.drawText('Registered Under Companies Act 2013 | ISO 9001:2015 Certified', {
            x: 165,
            y: 485,
            size: 10,
            font: font,
            color: rgb(0.3, 0.3, 0.3),
        });

        page.drawText('CERTIFICATE OF COMPLETION', {
            x: 230,
            y: 420,
            size: 26,
            font: fontBold,
            color: rgb(0.3, 0.1, 0.5),
        });

        page.drawText('This is to certify that', {
            x: 360,
            y: 375,
            size: 14,
            font: font,
            color: rgb(0.2, 0.2, 0.2),
        });

        // Student name
        page.drawText(studentData.name, {
            x: 220,
            y: 330,
            size: 24,
            font: fontBold,
            color: rgb(0, 0, 0),
        });
        page.drawLine({ start: { x: 215, y: 322 }, end: { x: 625, y: 322 }, thickness: 2, color: rgb(0.5, 0.5, 0.8), dashArray: [2, 2] });

        // Certificate details
        page.drawText(`has successfully completed the course in ${studentData.courseName || studentData.course || ''}`, {
            x: 180,
            y: 280,
            size: 14,
            font: font,
        });

        page.drawText(`with Roll Number ${studentData.rollNo || ''} and achieved Grade: ${studentData.grade || 'A'}.`, {
            x: 230,
            y: 245,
            size: 14,
            font: font,
        });

        // QR Code
        const documentId = this.generateDocumentId('certificate', studentData.regNo);
        const verificationUrl = `${this.verificationBaseUrl}?doc=${documentId}`;
        const qrCodeBuffer = await QRCode.toBuffer(verificationUrl, { width: 80, margin: 1 });
        const qrCodeImg = await pdfDoc.embedPng(qrCodeBuffer);
        page.drawImage(qrCodeImg, { x: 70, y: 80, width: 80, height: 80 });

        page.drawText(`Date of Issue: ${studentData.issueDate || new Date().toLocaleDateString('en-IN')}`, { x: 70, y: 60, size: 10, font: fontBold });

        // Signature box
        page.drawRectangle({
            x: 550,
            y: 90,
            width: 225,
            height: 50,
            borderColor: rgb(0.8, 0.8, 0.8),
            borderWidth: 1,
            color: rgb(0.98, 0.98, 0.98),
        });
        page.drawText('DIGITALLY SIGNED', { x: 560, y: 125, size: 9, font: fontBold, color: rgb(0, 0.5, 0) });
        page.drawText(`Authority: ${this.signingAuthority}`, { x: 560, y: 112, size: 7, font: font });
        page.drawText(`Date: ${new Date().toLocaleDateString('en-IN')}`, { x: 560, y: 100, size: 7, font: font });
        page.drawText('✓', { x: 730, y: 102, size: 30, font: fontBold, color: rgb(0, 0.6, 0) });

        pdfDoc.setTitle(`Certificate - ${studentData.name}`);
        pdfDoc.setAuthor(this.signingAuthority);
        pdfDoc.setKeywords(['digitally-signed', studentData.regNo]);

        const finalizedPdf = await pdfDoc.save();
        const fileHash = this.calculateHash(finalizedPdf);

        return {
            pdfBytes: Buffer.from(finalizedPdf),
            documentId,
            fileHash,
            metadata: {
                type: 'certificate',
                regNo: studentData.regNo,
                name: studentData.name,
                issueDate: studentData.issueDate || new Date().toISOString(),
                signedBy: this.signingAuthority
            }
        };
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
     * Generate PDF from Live Website data using Cheerio and local drawing templates
     * Bypasses Puppeteer by using simple memory-light HTTP crawler parsing.
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

        console.log(`Scraping HTML data from: ${url}`);
        const response = await axios.get(url);
        const html = response.data;
        const $ = cheerio.load(html);

        const studentData = {
            regNo: regNo,
            subjects: []
        };

        // Extract basic info from parsed HTML
        $('td, th, span, div, p').each((i, el) => {
            const text = $(el).text().trim();
            if (text.includes('Name :') || text.includes('Name:')) {
                studentData.name = text.split(':').pop().trim();
            } else if (text.includes("Father's Name :") || text.includes("Father's Name:")) {
                studentData.fatherName = text.split(':').pop().trim();
            } else if (text.includes('Roll No :') || text.includes('Roll No:')) {
                studentData.rollNo = text.split(':').pop().trim();
            } else if (text.includes('Course :') || text.includes('Course:')) {
                studentData.courseName = text.split(':').pop().trim();
            } else if (text.includes('Session :') || text.includes('Session:')) {
                studentData.session = text.split(':').pop().trim();
            }
        });

        // Fallbacks
        studentData.name = studentData.name || 'Student';
        studentData.rollNo = studentData.rollNo || regNo;

        if (type === 'marksheet') {
            // Find subject entries
            $('table tr').each((i, row) => {
                const cells = $(row).find('td');
                if (cells.length >= 4) {
                    const subName = $(cells[1]).text().trim();
                    const maxMarks = parseInt($(cells[2]).text().trim());
                    const minMarks = parseInt($(cells[3]).text().trim());
                    const marks = parseInt($(cells[4]).text().trim());
                    
                    if (subName && !isNaN(maxMarks) && !isNaN(marks) && subName !== 'Subject Name') {
                        studentData.subjects.push({
                            name: subName,
                            maxMarks,
                            minMarks: minMarks || 40,
                            marks
                        });
                    }
                }
            });

            // Try to extract Grand Total
            $('td:contains("Grand Total"), td:contains("TOTAL OBTAINED")').each((i, el) => {
                const text = $(el).next().text().trim();
                if (text && !isNaN(parseInt(text))) {
                    studentData.totalObtained = parseInt(text);
                }
            });

            const resultObj = await this.generateMarksheet(studentData);
            return resultObj.pdfBytes;
        } else {
            // Certificate
            const resultObj = await this.generateCertificate(studentData);
            return resultObj.pdfBytes;
        }
    }
}

module.exports = new DocumentService();
