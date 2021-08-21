import { Router } from 'express';
import { settings } from '../shared/AppSettings';
import { AuthProvider } from '../shared/AuthProvider';

let authProvider: AuthProvider;

// Export the base-router
const baseRouter = Router();

baseRouter.get('/', (req, res) => res.redirect('/maps'));

if (process.env.NODE_ENV === 'production') {
    authProvider = new AuthProvider(settings);

    baseRouter.get('/signin', authProvider.signIn);
    baseRouter.get('/signout', authProvider.signOut);
    baseRouter.get('/redirect', authProvider.handleRedirect);
}

baseRouter.get('/maps', function (req, res) {
    if (process.env.NODE_ENV === 'production' && !req.session.isAuthenticated && process.env.ENABLE_AZURE_AUTH === 'true') {
        res.redirect('/signin');
    }
    res.render('index', { title: 'My Maps' });
});

export default baseRouter;
