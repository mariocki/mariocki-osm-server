"use strict";
/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ErrorMessages = exports.ErrorCodes = void 0;
exports.ErrorCodes = {
    65001: "AADSTS65001",
    90118: "AADB2C90118"
};
exports.ErrorMessages = {
    NOT_PERMITTED: "Not permitted",
    INVALID_TOKEN: "Invalid token",
    CANNOT_DETERMINE_APP_STAGE: "Cannot determine application stage",
    NONCE_MISMATCH: "Nonce does not match",
    INTERACTION_REQUIRED: "interaction_required",
    TOKEN_NOT_FOUND: "No token found",
    TOKEN_NOT_DECODED: "Token cannot be decoded",
    TOKEN_NOT_VERIFIED: "Token cannot be verified",
    KEYS_NOT_OBTAINED: "Signing keys cannot be obtained"
};