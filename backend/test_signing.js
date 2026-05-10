const fs = require('fs');
const path = require('path');
const { PDFDocument } = require('pdf-lib');
const pkiSignerService = require('./src/services/pki-signer.service');

async function testSigning() {
    try {
        console.log('🚀 Starting Signing Test...');

        // 1. Create a dummy PDF
        const pdfDoc = await PDFDocument.create();
        const page = pdfDoc.addPage();
        page.drawText('This is a test certificate for signing verification.');
        const pdfBytes = await pdfDoc.save();
        const pdfBuffer = Buffer.from(pdfBytes);

        console.log('✅ Dummy PDF created');

        // 2. Sign it
        console.log('🔏 Signing PDF...');
        const signedPdfBuffer = await pkiSignerService.signPdf(pdfBuffer);

        console.log('✅ PDF Signed successfully');
        console.log(`original size: ${pdfBuffer.length}, signed size: ${signedPdfBuffer.length}`);

        // 3. Save output
        const outputPath = path.join(__dirname, 'test_signed.pdf');
        fs.writeFileSync(outputPath, signedPdfBuffer);
        console.log(`💾 Signed PDF saved to: ${outputPath}`);

    } catch (error) {
        console.error('❌ Test Failed:', error);
    }
}

testSigning();
