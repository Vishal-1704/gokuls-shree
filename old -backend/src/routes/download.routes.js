const express = require('express');
const db = require('../config/database');

const router = express.Router();

// Get all downloads
router.get('/', async (req, res) => {
    try {
        const result = await db.query(
            'SELECT * FROM downloads ORDER BY created_at DESC'
        );

        res.json({
            count: result.rows.length,
            downloads: result.rows.map(row => ({
                id: row.id.toString(),
                title: row.title,
                description: row.description,
                fileUrl: row.file_url,
                fileType: row.file_type,
                fileSize: row.file_size,
                downloadCount: row.download_count,
            })),
        });
    } catch (error) {
        console.error('Get downloads error:', error);
        res.status(500).json({ error: 'Failed to fetch downloads' });
    }
});

// Increment download count
router.post('/:id/download', async (req, res) => {
    try {
        const { id } = req.params;

        await db.query(
            'UPDATE downloads SET download_count = download_count + 1 WHERE id = $1',
            [id]
        );

        res.json({ success: true });
    } catch (error) {
        console.error('Download increment error:', error);
        res.status(500).json({ error: 'Failed to record download' });
    }
});

module.exports = router;
