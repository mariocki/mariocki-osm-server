import { Router } from 'express';
//import { settings } from '../shared/AppSettings';
//import { AuthProvider } from '../shared/AuthProvider';

//const authProvider = new AuthProvider(settings);

// Export the base-router
const baseRouter = Router();
// authentication routes
//baseRouter.get('/', (req , res) => res.redirect('/maps'));
//baseRouter.get('/signin', authProvider.signIn);
//baseRouter.get('/signout', authProvider.signOut);
//baseRouter.get('/redirect', authProvider.handleRedirect);

baseRouter.get('/maps', function (req, res) {
    //if (!req.session.isAuthenticated) {
    //    console.log("----- authenticating");
    //    res.redirect('/signin');
    //}
    //console.log("----- going to render index");
    res.render('index', { title: 'My Maps' });
});

export default baseRouter;
