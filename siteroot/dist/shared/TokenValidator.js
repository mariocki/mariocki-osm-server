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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TokenValidator = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const jwks_rsa_1 = __importDefault(require("jwks-rsa"));
const Errors_1 = require("./Errors");
const Constants_1 = require("./Constants");
class TokenValidator {
    constructor(appSettings, msalConfig) {
        /**
         * Validates the id token for a set of claims
         * @param {Object} idTokenClaims: decoded id token claims
         */
        this.validateIdToken = (idTokenClaims) => {
            const now = Math.round((new Date()).getTime() / 1000); // in UNIX format
            /**
             * At the very least, check for tenant, audience, issue and expiry dates.
             * For more information on validating id tokens, visit:
             * https://docs.microsoft.com/azure/active-directory/develop/id-tokens#validating-an-id_token
             */
            const checkAudience = idTokenClaims["aud"] === this.msalConfig.auth.clientId ? true : false;
            const checkTimestamp = idTokenClaims["iat"] <= now && idTokenClaims["exp"] >= now ? true : false;
            const checkTenant = (this.appSettings.policies && !idTokenClaims["tid"]) || idTokenClaims["tid"] === this.appSettings.credentials.tenantId ? true : false;
            return checkAudience && checkTimestamp && checkTenant;
        };
        /**
         * Validates the access token for signature and against a predefined set of claims
         * @param {string} accessToken: raw JWT token
         * @param {string} protectedRoute: used for checking scope
         */
        this.validateAccessToken = (accessToken, protectedRoute) => __awaiter(this, void 0, void 0, function* () {
            const now = Math.round((new Date()).getTime() / 1000); // in UNIX format
            if (!accessToken || accessToken === "" || accessToken === "undefined") {
                console.log(Errors_1.ErrorMessages.TOKEN_NOT_FOUND);
                return false;
            }
            // we will first decode to get kid parameter in header
            let decodedToken;
            try {
                decodedToken = jsonwebtoken_1.default.decode(accessToken, { complete: true });
            }
            catch (error) {
                console.log(Errors_1.ErrorMessages.TOKEN_NOT_DECODED);
                console.log(error);
                return false;
            }
            // obtains signing keys from discovery endpoint
            let keys;
            try {
                keys = yield this.getSigningKeys(decodedToken.header);
            }
            catch (error) {
                console.log(Errors_1.ErrorMessages.KEYS_NOT_OBTAINED);
                console.log(error);
                return false;
            }
            // verify the signature at header section using keys
            let verifiedToken;
            try {
                verifiedToken = jsonwebtoken_1.default.verify(accessToken, keys);
            }
            catch (error) {
                console.log(Errors_1.ErrorMessages.TOKEN_NOT_VERIFIED);
                console.log(error);
                return false;
            }
            /**
             * At the very least, validate the token with respect to issuer, audience, scope
             * and timestamp, though implementation and extent vary. For more information, visit:
             * https://docs.microsoft.com/azure/active-directory/develop/access-tokens#validating-tokens
             */
            const checkIssuer = verifiedToken['iss'].includes(this.appSettings.credentials.tenantId) ? true : false;
            const checkTimestamp = verifiedToken["iat"] <= now && verifiedToken["exp"] >= now ? true : false;
            const checkAudience = verifiedToken['aud'] === this.appSettings.credentials.clientId || verifiedToken['aud'] === 'api://' + this.appSettings.credentials.clientId ? true : false;
            const checkScopes = this.appSettings.protected.find(item => item.route === protectedRoute).scopes.every(scp => verifiedToken['scp'].includes(scp));
            if (checkAudience && checkIssuer && checkTimestamp && checkScopes) {
                return true;
            }
            return false;
        });
        /**
         * Fetches signing keys of an access token
         * from the authority discovery endpoint
         * @param {string} header
         */
        this.getSigningKeys = (header) => __awaiter(this, void 0, void 0, function* () {
            let jwksUri;
            // Check if a B2C application i.e. app has policies
            if (this.appSettings.policies) {
                jwksUri = `${this.msalConfig.auth.authority}/discovery/v2.0/keys`;
            }
            else {
                jwksUri = `${Constants_1.AuthorityStrings.AAD}${this.appSettings.credentials.tenantId}/discovery/v2.0/keys`;
            }
            const client = jwks_rsa_1.default({
                jwksUri: jwksUri
            });
            return (yield client.getSigningKeyAsync(header.kid)).getPublicKey();
        });
        this.appSettings = appSettings;
        this.msalConfig = msalConfig;
    }
}
exports.TokenValidator = TokenValidator;
