"use strict";
/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthProvider = void 0;
const msal_common_1 = require("@azure/msal-common");
const msal_node_1 = require("@azure/msal-node");
const ConfigurationUtils_1 = require("./ConfigurationUtils");
const TokenValidator_1 = require("./TokenValidator");
const Errors_1 = require("./Errors");
const constants = __importStar(require("./Constants"));
/**
 * A simple wrapper around MSAL Node ConfidentialClientApplication object.
 * It offers a collection of middleware and utility methods that automate
 * basic authentication and authorization tasks in Express MVC web apps.
 *
 * You must have express and express-sessions packages installed. Middleware here
 * can be used with express sessions in route controllers.
 *
 * Session variables accessible are as follows:
    * req.session.isAuthenticated => boolean
    * req.session.isAuthorized => boolean
    * req.session.idTokenClaims => object
    * req.session.homeAccountId => string
    * req.session.account => object
    * req.session.resourceName.accessToken => string
 */
class AuthProvider {
    /**
     * @param {JSON} appSettings
     * @param {Object} cache: cachePlugin
     */
    constructor(appSettings, cache = null) {
        // ========== MIDDLEWARE ===========
        /**
         * Initiate sign in flow
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         */
        this.signIn = (req, res) => __awaiter(this, void 0, void 0, function* () {
            /**
             * Request Configuration
             * We manipulate these three request objects below
             * to acquire a token with the appropriate claims
             */
            if (!req.session['authCodeRequest']) {
                req.session.authCodeRequest = {
                    authority: "",
                    scopes: [],
                    state: {},
                    redirectUri: ""
                };
            }
            if (!req.session['tokenRequest']) {
                req.session.tokenRequest = {
                    authority: "",
                    scopes: [],
                    state: {},
                    redirectUri: ""
                };
            }
            // current account id
            req.session.homeAccountId = "";
            // random GUID for csrf check 
            req.session.nonce = this.cryptoProvider.createNewGuid();
            // sign-in as usual
            const state = this.cryptoProvider.base64Encode(JSON.stringify({
                stage: constants.AppStages.SIGN_IN,
                path: req.route.path,
                nonce: req.session.nonce
            }));
            // get url to sign user in (and consent to scopes needed for application)
            this.getAuthCode(this.msalConfig.auth.authority, Object.values(constants.OIDCScopes), state, this.appSettings.settings.redirectUri, req, res);
        });
        /**
         * Initiate sign out and clean the session
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         * @param {Function} next: express next
         */
        this.signOut = (req, res) => __awaiter(this, void 0, void 0, function* () {
            /**
             * Construct a logout URI and redirect the user to end the
             * session with Azure AD/B2C. For more information, visit:
             * (AAD) https://docs.microsoft.com/azure/active-directory/develop/v2-protocols-oidc#send-a-sign-out-request
             * (B2C) https://docs.microsoft.com/azure/active-directory-b2c/openid-connect#send-a-sign-out-request
             */
            const logoutURI = `${this.msalConfig.auth.authority}/oauth2/v2.0/logout?post_logout_redirect_uri=${this.appSettings.settings.postLogoutRedirectUri}`;
            req.session.isAuthenticated = false;
            req.session.destroy(() => {
                res.redirect(logoutURI);
            });
        });
        /**
         * Middleware that handles redirect depending on request state
         * There are basically 2 stages: sign-in and acquire token
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         */
        this.handleRedirect = (req, res) => __awaiter(this, void 0, void 0, function* () {
            const state = JSON.parse(this.cryptoProvider.base64Decode(req.query.state));
            // check if nonce matches
            if (state.nonce === req.session.nonce) {
                switch (state.stage) {
                    case constants.AppStages.SIGN_IN: {
                        // token request should have auth code
                        const tokenRequest = {
                            redirectUri: this.appSettings.settings.redirectUri,
                            scopes: Object.keys(constants.OIDCScopes),
                            code: req.query.code,
                        };
                        try {
                            // exchange auth code for tokens
                            const tokenResponse = yield this.msalClient.acquireTokenByCode(tokenRequest);
                            console.log("\nResponse: \n:", tokenResponse);
                            if (this.tokenValidator.validateIdToken(tokenResponse.idTokenClaims)) {
                                req.session.homeAccountId = tokenResponse.account.homeAccountId;
                                // assign session variables
                                req.session.idTokenClaims = tokenResponse.idTokenClaims;
                                req.session.isAuthenticated = true;
                                return res.status(200).redirect(this.appSettings.settings.homePageRoute);
                            }
                            else {
                                console.log(Errors_1.ErrorMessages.INVALID_TOKEN);
                                return res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED);
                            }
                        }
                        catch (error) {
                            console.log(error);
                            res.status(500).send(error);
                        }
                        break;
                    }
                    case constants.AppStages.ACQUIRE_TOKEN: {
                        // get the name of the resource associated with scope
                        const resourceName = this.getResourceName(state.path);
                        const tokenRequest = {
                            code: req.query.code,
                            scopes: this.appSettings.resources[resourceName].scopes,
                            redirectUri: this.appSettings.settings.redirectUri,
                        };
                        try {
                            const tokenResponse = yield this.msalClient.acquireTokenByCode(tokenRequest);
                            console.log("\nResponse: \n:", tokenResponse);
                            req.session[resourceName].accessToken = tokenResponse.accessToken;
                            return res.status(200).redirect(state.path);
                        }
                        catch (error) {
                            console.log(error);
                            res.status(500).send(error);
                        }
                        break;
                    }
                    default:
                        res.status(500).send(Errors_1.ErrorMessages.CANNOT_DETERMINE_APP_STAGE);
                        break;
                }
            }
            else {
                console.log(Errors_1.ErrorMessages.NONCE_MISMATCH);
                res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED);
            }
        });
        /**
         * Middleware that gets tokens and calls web APIs
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         * @param {Function} next: express next
         */
        this.getToken = (req, res, next) => __awaiter(this, void 0, void 0, function* () {
            // get scopes for token request
            const scopes = Object.values(this.appSettings.resources)
                .find((resource) => resource.callingPageRoute === req.route.path).scopes;
            const resourceName = this.getResourceName(req.route.path);
            if (!req.session[resourceName]) {
                req.session[resourceName] = {
                    accessToken: null,
                    resourceResponse: null,
                };
            }
            try {
                let account;
                try {
                    account = yield this.msalClient.getTokenCache().getAccountByHomeId(req.session.homeAccountId);
                    if (!account) {
                        throw new Error(Errors_1.ErrorMessages.INTERACTION_REQUIRED);
                    }
                }
                catch (error) {
                    console.log(error);
                    throw new msal_common_1.InteractionRequiredAuthError(Errors_1.ErrorMessages.INTERACTION_REQUIRED);
                }
                const silentRequest = {
                    account: account,
                    scopes: scopes,
                };
                // acquire token silently to be used in resource call
                const tokenResponse = yield this.msalClient.acquireTokenSilent(silentRequest);
                console.log("\nSuccessful silent token acquisition:\n Response: \n:", tokenResponse);
                // In B2C scenarios, sometimes an access token is returned empty.
                // In that case, we will acquire token interactively instead.
                if (tokenResponse.accessToken.length === 0) {
                    console.log(Errors_1.ErrorMessages.TOKEN_NOT_FOUND);
                    throw new msal_common_1.InteractionRequiredAuthError(Errors_1.ErrorMessages.INTERACTION_REQUIRED);
                }
                req.session[resourceName].accessToken = tokenResponse.accessToken;
                return next();
            }
            catch (error) {
                // in case there are no cached tokens, initiate an interactive call
                if (error instanceof msal_common_1.InteractionRequiredAuthError) {
                    const state = this.cryptoProvider.base64Encode(JSON.stringify({
                        stage: constants.AppStages.ACQUIRE_TOKEN,
                        path: req.route.path,
                        nonce: req.session.nonce
                    }));
                    // initiate the first leg of auth code grant to get token
                    this.getAuthCode(this.msalConfig.auth.authority, scopes, state, this.appSettings.settings.redirectUri, req, res);
                }
            }
        });
        // ============== GUARD ===============
        /**
         * Check if authenticated in session
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         * @param {Function} next: express next
         */
        this.isAuthenticated = (req, res, next) => {
            if (req.session) {
                if (!req.session.isAuthenticated) {
                    return res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED);
                }
                next();
            }
            else {
                return res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED);
            }
        };
        /**
         * Receives access token in req authorization header
         * and validates it using the jwt.verify
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         * @param {Function} next: express next
         */
        this.isAuthorized = (req, res, next) => __awaiter(this, void 0, void 0, function* () {
            const accessToken = req.headers.authorization.split(' ')[1];
            if (req.headers.authorization) {
                if (!(yield this.tokenValidator.validateAccessToken(accessToken, req.route.path))) {
                    return res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED);
                }
                next();
            }
            else {
                res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED);
            }
        });
        // ============== UTILS ===============
        /**
         * This method is used to generate an auth code request
         * @param {string} authority: the authority to request the auth code from
         * @param {Array} scopes: scopes to request the auth code for
         * @param {string} state: state of the application
         * @param {string} redirect: redirect URI
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         */
        this.getAuthCode = (authority, scopes, state, redirect, req, res) => __awaiter(this, void 0, void 0, function* () {
            // prepare the request
            req.session.authCodeRequest.authority = authority;
            req.session.authCodeRequest.scopes = scopes;
            req.session.authCodeRequest.state = state;
            req.session.authCodeRequest.redirectUri = redirect;
            req.session.tokenRequest.authority = authority;
            // request an authorization code to exchange for tokens
            try {
                const response = yield this.msalClient.getAuthCodeUrl(req.session.authCodeRequest);
                return res.redirect(response);
            }
            catch (error) {
                console.log(JSON.stringify(error));
                return res.status(500).send(error);
            }
        });
        /**
         * Util method to get the resource name for a given callingPageRoute (appSettings.json)
         * @param {string} path: /path string that the resource is associated with
         */
        this.getResourceName = (path) => {
            const index = Object.values(this.appSettings.resources).findIndex((resource) => resource.callingPageRoute === path);
            const resourceName = Object.keys(this.appSettings.resources)[index];
            return resourceName;
        };
        ConfigurationUtils_1.ConfigurationUtils.validateAppSettings(appSettings);
        this.cryptoProvider = new msal_node_1.CryptoProvider();
        this.appSettings = appSettings;
        this.msalConfig = ConfigurationUtils_1.ConfigurationUtils.getMsalConfiguration(appSettings, cache);
        this.tokenValidator = new TokenValidator_1.TokenValidator(this.appSettings, this.msalConfig);
        this.msalClient = new msal_node_1.ConfidentialClientApplication(this.msalConfig);
    }
}
exports.AuthProvider = AuthProvider;
