import { Router } from 'express';
if (process.env.NODE_ENV === 'production') {
    import { settings } from '../shared/AppSettings';
    import { AuthProvider } from '../shared/AuthProvider';
}

const authProvider = new AuthProvider(settings);

// Export the base-router
const baseRouter = Router();
// authentication routes
baseRouter.get('/', (req, res) => res.redirect('/maps'));
if (process.env.NODE_ENV === 'production') {
    baseRouter.get('/signin', authProvider.signIn);
    baseRouter.get('/signout', authProvider.signOut);
    baseRouter.get('/redirect', authProvider.handleRedirect);
}

baseRouter.get('/maps', function (req, res) {
    if (process.env.NODE_ENV === 'production' && !req.session.isAuthenticated) {
        res.redirect('/signin');
    }
    res.render('index', { title: 'My Maps' });
});

export default baseRouter;
