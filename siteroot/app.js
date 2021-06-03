var msal = require('@azure/msal-node');
var express = require('express');
var cookieParser = require('cookie-parser');
var logger = require('morgan');

var app = express();

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use('/maps', express.static('public'));

if (process.env.AZURE_SECRET != '') {
    const clientConfig = {
        auth: {
            clientId: process.env.AZURE_CLIENT_ID,
            authority: "https://login.microsoftonline.com/" + process.env.AZURE_TENANT,
            clientSecret: process.env.AZURE_SECRET
        },
        system: {
            loggerOptions: {
                loggerCallback(loglevel, message, containsPii) {
                    console.log(message);
                },
                piiLoggingEnabled: false,
                logLevel: msal.LogLevel.Verbose,
            }
        }
    };

    // Create msal application object
    const cca = new msal.ConfidentialClientApplication(clientConfig);

    app.get('/', (req, res) => {
        const authCodeUrlParameters = {
            scopes: ["user.read"],
            redirectUri: process.env.AZURE_REDIRECT_URL,
        };

        // get url to sign user in and consent to scopes needed for application
        cca.getAuthCodeUrl(authCodeUrlParameters).then((response) => {
            res.redirect(response);
        }).catch((error) => console.log(JSON.stringify(error)));
    });

    app.get('/maps', (req, res) => {
        const tokenRequest = {
            code: req.query.code,
            scopes: ["user.read"],
            redirectUri: process.env.AZURE_REDIRECT_URL,
        };

        cca.acquireTokenByCode(tokenRequest).then((response) => {
            console.log("\nResponse: \n:", response);
            res.sendStatus(200);
        }).catch((error) => {
            console.log(error);
            res.status(500).send(error);
        });
    });
} else {
    app.get('/', (req, res) => {
        res.redirect('/maps');
    });
}

module.exports = app;