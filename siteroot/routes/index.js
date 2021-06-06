var express = require('express');
const settings = require('../appSettings.js');
const { AuthProvider } = require('../public/javascripts/AuthProvider');

var router = express.Router();

var authProvider = new AuthProvider(settings);

// app routes
router.get('/', (req, res, next) => res.redirect('/maps'));

// authentication routes
router.get('/signin', authProvider.signIn);
router.get('/signout', authProvider.signOut);
router.get('/redirect', authProvider.handleRedirect);

router.get('/maps', function(req, res, next) {
    if (!req.session.isAuthenticated) {
        res.redirect('/signin');
    }
    res.render('index', { title: 'My Maps' });
});

module.exports = router;