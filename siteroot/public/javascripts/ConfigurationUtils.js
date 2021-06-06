"use strict";
/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConfigurationUtils = void 0;
var msal_node_1 = require("@azure/msal-node");
var Constants_1 = require("./Constants");
var ConfigurationUtils = /** @class */ (function () {
    function ConfigurationUtils() {
    }
    /**
     * Validates the fields in the custom JSON configuration file
     * @param {JSON} config: configuration file
     */
    ConfigurationUtils.validateAppSettings = function (config) {
        if (!config.credentials.clientId || config.credentials.clientId === "Enter_the_Application_Id_Here") {
            throw new Error("No clientId provided!");
        }
        if (!config.credentials.tenantId || config.credentials.tenantId === "Enter_the_Tenant_Info_Here") {
            throw new Error("No tenantId provided!");
        }
        if (!config.credentials.clientSecret || config.credentials.clientSecret === "Enter_the_Client_Secret_Here") {
            throw new Error("No clientSecret provided!");
        }
        if (!config.settings.redirectUri || config.settings.redirectUri === "Enter_the_Redirect_Uri_Here") {
            throw new Error("No postLogoutRedirectUri provided!");
        }
        if (!config.settings.postLogoutRedirectUri || config.settings.postLogoutRedirectUri === "Enter_the_Post_Logout_Redirect_Uri_Here") {
            throw new Error("No postLogoutRedirectUri provided!");
        }
        if (!config.settings.homePageRoute) {
            throw new Error("No homePageRoute provided!");
        }
    };
    /**
     * Maps the custom JSON configuration file to configuration
     * object expected by MSAL Node ConfidentialClientApplication
     * @param {JSON} config: configuration file
     * @param {Object} cachePlugin: passed at initialization
     */
    ConfigurationUtils.getMsalConfiguration = function (config, cachePlugin) {
        if (cachePlugin === void 0) { cachePlugin = null; }
        return {
            auth: {
                clientId: config.credentials.clientId,
                authority: config.policies ? config.policies.signUpSignIn.authority : Constants_1.AuthorityStrings.AAD + config.credentials.tenantId,
                clientSecret: config.credentials.clientSecret,
                redirectUri: config.settings ? config.settings.redirectUri : "",
                knownAuthorities: config.policies ? [config.policies.authorityDomain] : [], // in B2C scenarios
            },
            cache: {
                cachePlugin: cachePlugin,
            },
            system: {
                loggerOptions: {
                    loggerCallback: function (loglevel, message, containsPii) {
                        console.log(message);
                    },
                    piiLoggingEnabled: false,
                    logLevel: msal_node_1.LogLevel.Verbose,
                }
            }
        };
    };
    return ConfigurationUtils;
}());
exports.ConfigurationUtils = ConfigurationUtils;
