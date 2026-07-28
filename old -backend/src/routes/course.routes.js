const express = require('express');
const { supabase } = require('../config/supabase');

const router = express.Router();

// Get all courses
router.get('/', async (req, res) => {
    try {
        const { category } = req.query;

        let query = supabase
            .from('courses')
            .select('*')
            .eq('status', 1);

        if (category) {
            query = query.eq('category', category);
        }

        query = query.order('title');

        const { data, error } = await query;
        if (error) throw error;

        res.json({
            count: data.length,
            courses: data.map(row => ({
                id: row.id.toString(),
                title: row.title,
                category: row.category,
                duration: row.duration,
                eligibility: row.eligibility,
                description: row.description,
                imageUrl: row.image_url,
            })),
        });
    } catch (error) {
        console.error('Get courses error:', error);
        res.status(500).json({ error: 'Failed to fetch courses' });
    }
});

// Get course by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const { data, error } = await supabase
            .from('courses')
            .select('*')
            .eq('id', parseInt(id))
            .eq('status', 1)
            .maybeSingle();

        if (error) throw error;
        if (!data) {
            return res.status(404).json({ error: 'Course not found' });
        }

        res.json({
            id: data.id.toString(),
            title: data.title,
            category: data.category,
            duration: data.duration,
            eligibility: data.eligibility,
            description: data.description,
            imageUrl: data.image_url,
        });
    } catch (error) {
        console.error('Get course error:', error);
        res.status(500).json({ error: 'Failed to fetch course' });
    }
});

// Get course categories
router.get('/meta/categories', async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('courses')
            .select('category')
            .eq('status', 1);

        if (error) throw error;

        const categories = [...new Set(data.map(row => row.category).filter(Boolean))].sort();

        res.json({
            categories,
        });
    } catch (error) {
        console.error('Get categories error:', error);
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
});

module.exports = router;

