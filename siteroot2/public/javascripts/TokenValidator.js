"use strict";
/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TokenValidator = void 0;
var jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
var jwks_rsa_1 = __importDefault(require("jwks-rsa"));
var Errors_1 = require("./Errors");
var Constants_1 = require("./Constants");
var TokenValidator = /** @class */ (function () {
    function TokenValidator(appSettings, msalConfig) {
        var _this = this;
        /**
         * Validates the id token for a set of claims
         * @param {Object} idTokenClaims: decoded id token claims
         */
        this.validateIdToken = function (idTokenClaims) {
            var now = Math.round((new Date()).getTime() / 1000); // in UNIX format
            /**
             * At the very least, check for tenant, audience, issue and expiry dates.
             * For more information on validating id tokens, visit:
             * https://docs.microsoft.com/azure/active-directory/develop/id-tokens#validating-an-id_token
             */
            var checkAudience = idTokenClaims["aud"] === _this.msalConfig.auth.clientId ? true : false;
            var checkTimestamp = idTokenClaims["iat"] <= now && idTokenClaims["exp"] >= now ? true : false;
            var checkTenant = (_this.appSettings.policies && !idTokenClaims["tid"]) || idTokenClaims["tid"] === _this.appSettings.credentials.tenantId ? true : false;
            return checkAudience && checkTimestamp && checkTenant;
        };
        /**
         * Validates the access token for signature and against a predefined set of claims
         * @param {string} accessToken: raw JWT token
         * @param {string} protectedRoute: used for checking scope
         */
        this.validateAccessToken = function (accessToken, protectedRoute) { return __awaiter(_this, void 0, void 0, function () {
            var now, decodedToken, keys, error_1, verifiedToken, checkIssuer, checkTimestamp, checkAudience, checkScopes;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        now = Math.round((new Date()).getTime() / 1000);
                        if (!accessToken || accessToken === "" || accessToken === "undefined") {
                            console.log(Errors_1.ErrorMessages.TOKEN_NOT_FOUND);
                            return [2 /*return*/, false];
                        }
                        try {
                            decodedToken = jsonwebtoken_1.default.decode(accessToken, { complete: true });
                        }
                        catch (error) {
                            console.log(Errors_1.ErrorMessages.TOKEN_NOT_DECODED);
                            console.log(error);
                            return [2 /*return*/, false];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.getSigningKeys(decodedToken.header)];
                    case 2:
                        keys = _a.sent();
                        return [3 /*break*/, 4];
                    case 3:
                        error_1 = _a.sent();
                        console.log(Errors_1.ErrorMessages.KEYS_NOT_OBTAINED);
                        console.log(error_1);
                        return [2 /*return*/, false];
                    case 4:
                        try {
                            verifiedToken = jsonwebtoken_1.default.verify(accessToken, keys);
                        }
                        catch (error) {
                            console.log(Errors_1.ErrorMessages.TOKEN_NOT_VERIFIED);
                            console.log(error);
                            return [2 /*return*/, false];
                        }
                        checkIssuer = verifiedToken['iss'].includes(this.appSettings.credentials.tenantId) ? true : false;
                        checkTimestamp = verifiedToken["iat"] <= now && verifiedToken["exp"] >= now ? true : false;
                        checkAudience = verifiedToken['aud'] === this.appSettings.credentials.clientId || verifiedToken['aud'] === 'api://' + this.appSettings.credentials.clientId ? true : false;
                        checkScopes = this.appSettings.protected.find(function (item) { return item.route === protectedRoute; }).scopes.every(function (scp) { return verifiedToken['scp'].includes(scp); });
                        if (checkAudience && checkIssuer && checkTimestamp && checkScopes) {
                            return [2 /*return*/, true];
                        }
                        return [2 /*return*/, false];
                }
            });
        }); };
        /**
         * Fetches signing keys of an access token
         * from the authority discovery endpoint
         * @param {string} header
         */
        this.getSigningKeys = function (header) { return __awaiter(_this, void 0, void 0, function () {
            var jwksUri, client;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        // Check if a B2C application i.e. app has policies
                        if (this.appSettings.policies) {
                            jwksUri = this.msalConfig.auth.authority + "/discovery/v2.0/keys";
                        }
                        else {
                            jwksUri = "" + Constants_1.AuthorityStrings.AAD + this.appSettings.credentials.tenantId + "/discovery/v2.0/keys";
                        }
                        client = jwks_rsa_1.default({
                            jwksUri: jwksUri
                        });
                        return [4 /*yield*/, client.getSigningKeyAsync(header.kid)];
                    case 1: return [2 /*return*/, (_a.sent()).getPublicKey()];
                }
            });
        }); };
        this.appSettings = appSettings;
        this.msalConfig = msalConfig;
    }
    return TokenValidator;
}());
exports.TokenValidator = TokenValidator;
