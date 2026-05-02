import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const upsert = mutation({
  args: {
    name: v.string(),
    universe: v.string(),
    role: v.string(),
    voiceId: v.string(),
    personalityPrompt: v.string(),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("guestCharacters")
      .withIndex("by_name", (q) => q.eq("name", args.name))
      .unique();
    if (existing) {
      await ctx.db.patch(existing._id, {
        universe: args.universe,
        role: args.role,
        voiceId: args.voiceId,
        personalityPrompt: args.personalityPrompt,
      });
      return existing._id;
    }
    return await ctx.db.insert("guestCharacters", {
      ...args,
      generatedAt: Date.now(),
      usedInEpisodeIds: [],
    });
  },
});

export const findByUniverse = query({
  args: { universe: v.string() },
  handler: async (ctx, { universe }) => {
    return await ctx.db
      .query("guestCharacters")
      .withIndex("by_universe", (q) => q.eq("universe", universe))
      .collect();
  },
});

export const findByName = query({
  args: { name: v.string() },
  handler: async (ctx, { name }) => {
    return await ctx.db
      .query("guestCharacters")
      .withIndex("by_name", (q) => q.eq("name", name))
      .unique();
  },
});
