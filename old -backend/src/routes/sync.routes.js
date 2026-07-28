const express = require('express');
const syncService = require('../services/sync.service');
const router = express.Router();

// Trigger Login Test
router.post('/test-login', async (req, res) => {
    const success = await syncService.login();
    if (success) {
        res.json({ status: 'success', message: 'Connected to Gokul Shree Admin Panel' });
    } else {
        res.status(401).json({ status: 'error', message: 'Login Failed. Check PHP_ADMIN_USER in .env' });
    }
});

// Sync Students
router.post('/students', async (req, res) => {
    try {
        const students = await syncService.getStudents();
        // TODO: Save to database (this is next step)
        res.json({ count: students.length, data: students });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
