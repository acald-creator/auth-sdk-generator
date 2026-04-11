import { query } from "./_generated/server";

export const whoami = query({
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      return null;
    }
    return {
      subject: identity.subject,
      issuer: identity.issuer,
      name: identity.name,
      email: identity.email,
      tokenIdentifier: identity.tokenIdentifier,
    };
  },
});
