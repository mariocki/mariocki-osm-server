import { AppSettings } from "./Types"

export const settings: AppSettings = {
    credentials: {
        clientId: process.env.AZURE_CLIENT_ID,
        tenantId: process.env.AZURE_TENANT,
        clientSecret: process.env.AZURE_SECRET
    },
    settings: {
        redirectUri: process.env.AZURE_REDIRECT_URL,
        postLogoutRedirectUri: "https://google.com",
        homePageRoute: "/maps"
    },
    resources : null,
    policies : null,
    protected : null
}
