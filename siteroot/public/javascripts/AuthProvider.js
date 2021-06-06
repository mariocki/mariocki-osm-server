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
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthProvider = void 0;
var msal_common_1 = require("@azure/msal-common");
var msal_node_1 = require("@azure/msal-node");
var ConfigurationUtils_1 = require("./ConfigurationUtils");
var TokenValidator_1 = require("./TokenValidator");
var Errors_1 = require("./Errors");
var constants = __importStar(require("./Constants"));
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
var AuthProvider = /** @class */ (function () {
    /**
     * @param {JSON} appSettings
     * @param {Object} cache: cachePlugin
     */
    function AuthProvider(appSettings, cache) {
        var _this = this;
        if (cache === void 0) { cache = null; }
        // ========== MIDDLEWARE ===========
        /**
         * Initiate sign in flow
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         */
        this.signIn = function (req, res) { return __awaiter(_this, void 0, void 0, function () {
            var state;
            return __generator(this, function (_a) {
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
                console.log("req nonce: " + req.session.nonce);
                state = this.cryptoProvider.base64Encode(JSON.stringify({
                    stage: constants.AppStages.SIGN_IN,
                    path: req.route.path,
                    nonce: req.session.nonce
                }));
                // get url to sign user in (and consent to scopes needed for application)
                this.getAuthCode(this.msalConfig.auth.authority, Object.values(constants.OIDCScopes), state, this.appSettings.settings.redirectUri, req, res);
                return [2 /*return*/];
            });
        }); };
        /**
         * Initiate sign out and clean the session
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         * @param {Function} next: express next
         */
        this.signOut = function (req, res) { return __awaiter(_this, void 0, void 0, function () {
            var logoutURI;
            return __generator(this, function (_a) {
                logoutURI = this.msalConfig.auth.authority + "/oauth2/v2.0/logout?post_logout_redirect_uri=" + this.appSettings.settings.postLogoutRedirectUri;
                req.session.isAuthenticated = false;
                req.session.destroy(function () {
                    res.redirect(logoutURI);
                });
                return [2 /*return*/];
            });
        }); };
        /**
         * Middleware that handles redirect depending on request state
         * There are basically 2 stages: sign-in and acquire token
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         */
        this.handleRedirect = function (req, res) { return __awaiter(_this, void 0, void 0, function () {
            var state, _a, tokenRequest, tokenResponse, error_1, resourceName, tokenRequest, tokenResponse, error_2;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        state = JSON.parse(this.cryptoProvider.base64Decode(req.query.state));
                        console.log("res nonce: " + state.nonce);
                        console.log("req nonce: " + req.session.nonce);
                        if (!(state.nonce === req.session.nonce)) return [3 /*break*/, 13];
                        _a = state.stage;
                        switch (_a) {
                            case constants.AppStages.SIGN_IN: return [3 /*break*/, 1];
                            case constants.AppStages.ACQUIRE_TOKEN: return [3 /*break*/, 6];
                        }
                        return [3 /*break*/, 11];
                    case 1:
                        tokenRequest = {
                            redirectUri: this.appSettings.settings.redirectUri,
                            scopes: Object.keys(constants.OIDCScopes),
                            code: req.query.code,
                        };
                        _b.label = 2;
                    case 2:
                        _b.trys.push([2, 4, , 5]);
                        return [4 /*yield*/, this.msalClient.acquireTokenByCode(tokenRequest)];
                    case 3:
                        tokenResponse = _b.sent();
                        console.log("\nResponse: \n:", tokenResponse);
                        if (this.tokenValidator.validateIdToken(tokenResponse.idTokenClaims)) {
                            req.session.homeAccountId = tokenResponse.account.homeAccountId;
                            // assign session variables
                            req.session.idTokenClaims = tokenResponse.idTokenClaims;
                            req.session.isAuthenticated = true;
                            return [2 /*return*/, res.status(200).redirect(this.appSettings.settings.homePageRoute)];
                        }
                        else {
                            console.log(Errors_1.ErrorMessages.INVALID_TOKEN);
                            return [2 /*return*/, res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED)];
                        }
                        return [3 /*break*/, 5];
                    case 4:
                        error_1 = _b.sent();
                        console.log(error_1);
                        res.status(500).send(error_1);
                        return [3 /*break*/, 5];
                    case 5: return [3 /*break*/, 12];
                    case 6:
                        resourceName = this.getResourceName(state.path);
                        tokenRequest = {
                            code: req.query.code,
                            scopes: this.appSettings.resources[resourceName].scopes,
                            redirectUri: this.appSettings.settings.redirectUri,
                        };
                        _b.label = 7;
                    case 7:
                        _b.trys.push([7, 9, , 10]);
                        return [4 /*yield*/, this.msalClient.acquireTokenByCode(tokenRequest)];
                    case 8:
                        tokenResponse = _b.sent();
                        console.log("\nResponse: \n:", tokenResponse);
                        req.session[resourceName].accessToken = tokenResponse.accessToken;
                        return [2 /*return*/, res.status(200).redirect(state.path)];
                    case 9:
                        error_2 = _b.sent();
                        console.log(error_2);
                        res.status(500).send(error_2);
                        return [3 /*break*/, 10];
                    case 10: return [3 /*break*/, 12];
                    case 11:
                        res.status(500).send(Errors_1.ErrorMessages.CANNOT_DETERMINE_APP_STAGE);
                        return [3 /*break*/, 12];
                    case 12: return [3 /*break*/, 14];
                    case 13:
                        console.log(Errors_1.ErrorMessages.NONCE_MISMATCH);
                        res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED);
                        _b.label = 14;
                    case 14: return [2 /*return*/];
                }
            });
        }); };
        /**
         * Middleware that gets tokens and calls web APIs
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         * @param {Function} next: express next
         */
        this.getToken = function (req, res, next) { return __awaiter(_this, void 0, void 0, function () {
            var scopes, resourceName, account, error_3, silentRequest, tokenResponse, error_4, state;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        scopes = Object.values(this.appSettings.resources)
                            .find(function (resource) { return resource.callingPageRoute === req.route.path; }).scopes;
                        resourceName = this.getResourceName(req.route.path);
                        if (!req.session[resourceName]) {
                            req.session[resourceName] = {
                                accessToken: null,
                                resourceResponse: null,
                            };
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 7, , 8]);
                        account = void 0;
                        _a.label = 2;
                    case 2:
                        _a.trys.push([2, 4, , 5]);
                        return [4 /*yield*/, this.msalClient.getTokenCache().getAccountByHomeId(req.session.homeAccountId)];
                    case 3:
                        account = _a.sent();
                        if (!account) {
                            throw new Error(Errors_1.ErrorMessages.INTERACTION_REQUIRED);
                        }
                        return [3 /*break*/, 5];
                    case 4:
                        error_3 = _a.sent();
                        console.log(error_3);
                        throw new msal_common_1.InteractionRequiredAuthError(Errors_1.ErrorMessages.INTERACTION_REQUIRED);
                    case 5:
                        silentRequest = {
                            account: account,
                            scopes: scopes,
                        };
                        return [4 /*yield*/, this.msalClient.acquireTokenSilent(silentRequest)];
                    case 6:
                        tokenResponse = _a.sent();
                        console.log("\nSuccessful silent token acquisition:\n Response: \n:", tokenResponse);
                        // In B2C scenarios, sometimes an access token is returned empty.
                        // In that case, we will acquire token interactively instead.
                        if (tokenResponse.accessToken.length === 0) {
                            console.log(Errors_1.ErrorMessages.TOKEN_NOT_FOUND);
                            throw new msal_common_1.InteractionRequiredAuthError(Errors_1.ErrorMessages.INTERACTION_REQUIRED);
                        }
                        req.session[resourceName].accessToken = tokenResponse.accessToken;
                        return [2 /*return*/, next()];
                    case 7:
                        error_4 = _a.sent();
                        // in case there are no cached tokens, initiate an interactive call
                        if (error_4 instanceof msal_common_1.InteractionRequiredAuthError) {
                            state = this.cryptoProvider.base64Encode(JSON.stringify({
                                stage: constants.AppStages.ACQUIRE_TOKEN,
                                path: req.route.path,
                                nonce: req.session.nonce
                            }));
                            // initiate the first leg of auth code grant to get token
                            this.getAuthCode(this.msalConfig.auth.authority, scopes, state, this.appSettings.settings.redirectUri, req, res);
                        }
                        return [3 /*break*/, 8];
                    case 8: return [2 /*return*/];
                }
            });
        }); };
        // ============== GUARD ===============
        /**
         * Check if authenticated in session
         * @param {Object} req: express request object
         * @param {Object} res: express response object
         * @param {Function} next: express next
         */
        this.isAuthenticated = function (req, res, next) {
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
        this.isAuthorized = function (req, res, next) { return __awaiter(_this, void 0, void 0, function () {
            var accessToken;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        accessToken = req.headers.authorization.split(' ')[1];
                        if (!req.headers.authorization) return [3 /*break*/, 2];
                        return [4 /*yield*/, this.tokenValidator.validateAccessToken(accessToken, req.route.path)];
                    case 1:
                        if (!(_a.sent())) {
                            return [2 /*return*/, res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED)];
                        }
                        next();
                        return [3 /*break*/, 3];
                    case 2:
                        res.status(401).send(Errors_1.ErrorMessages.NOT_PERMITTED);
                        _a.label = 3;
                    case 3: return [2 /*return*/];
                }
            });
        }); };
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
        this.getAuthCode = function (authority, scopes, state, redirect, req, res) { return __awaiter(_this, void 0, void 0, function () {
            var response, error_5;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        // prepare the request
                        req.session.authCodeRequest.authority = authority;
                        req.session.authCodeRequest.scopes = scopes;
                        req.session.authCodeRequest.state = state;
                        req.session.authCodeRequest.redirectUri = redirect;
                        req.session.tokenRequest.authority = authority;
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.msalClient.getAuthCodeUrl(req.session.authCodeRequest)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, res.redirect(response)];
                    case 3:
                        error_5 = _a.sent();
                        console.log(JSON.stringify(error_5));
                        return [2 /*return*/, res.status(500).send(error_5)];
                    case 4: return [2 /*return*/];
                }
            });
        }); };
        /**
         * Util method to get the resource name for a given callingPageRoute (appSettings.json)
         * @param {string} path: /path string that the resource is associated with
         */
        this.getResourceName = function (path) {
            var index = Object.values(_this.appSettings.resources).findIndex(function (resource) { return resource.callingPageRoute === path; });
            var resourceName = Object.keys(_this.appSettings.resources)[index];
            return resourceName;
        };
        ConfigurationUtils_1.ConfigurationUtils.validateAppSettings(appSettings);
        this.cryptoProvider = new msal_node_1.CryptoProvider();
        this.appSettings = appSettings;
        this.msalConfig = ConfigurationUtils_1.ConfigurationUtils.getMsalConfiguration(appSettings, cache);
        this.tokenValidator = new TokenValidator_1.TokenValidator(this.appSettings, this.msalConfig);
        this.msalClient = new msal_node_1.ConfidentialClientApplication(this.msalConfig);
    }
    return AuthProvider;
}());
exports.AuthProvider = AuthProvider;
