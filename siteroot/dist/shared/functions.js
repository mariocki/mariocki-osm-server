"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.pErr = void 0;
const Logger_1 = __importDefault(require("./Logger"));
const pErr = (err) => {
    if (err) {
        Logger_1.default.err(err);
    }
};
exports.pErr = pErr;
