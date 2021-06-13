"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const AppSettings_1 = require("../shared/AppSettings");
const AuthProvider_1 = require("../shared/AuthProvider");
const authProvider = new AuthProvider_1.AuthProvider(AppSettings_1.settings);
// Export the base-router
const baseRouter = express_1.Router();
// authentication routes
baseRouter.get('/', (req, res) => res.redirect('/maps'));
baseRouter.get('/signin', authProvider.signIn);
baseRouter.get('/signout', authProvider.signOut);
baseRouter.get('/redirect', authProvider.handleRedirect);
baseRouter.get('/maps', function (req, res) {
    if (!req.session.isAuthenticated) {
        console.log("----- authenticating");
        res.redirect('/signin');
    }
    console.log("----- going to render index");
    res.render('index', { title: 'My Maps' });
});
exports.default = baseRouter;
