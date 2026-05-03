import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const saveResearch = mutation({
  args: {
    grievanceId: v.string(),
    sources: v.any(),
    keyFacts: v.array(v.string()),
    plaintiffEvidence: v.array(v.string()),
    defendantEvidence: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("canonResearch")
      .withIndex("by_grievance", (q) => q.eq("grievanceId", args.grievanceId))
      .first();
    const payload = {
      grievanceId: args.grievanceId,
      sources: args.sources,
      keyFacts: args.keyFacts,
      plaintiffEvidence: args.plaintiffEvidence,
      defendantEvidence: args.defendantEvidence,
      researchedAt: Date.now(),
    };
    if (existing) {
      await ctx.db.patch(existing._id, payload);
      return existing._id;
    }
    return await ctx.db.insert("canonResearch", payload);
  },
});

export const getResearchByGrievance = query({
  args: { grievanceId: v.string() },
  handler: async (ctx, { grievanceId }) =>
    await ctx.db
      .query("canonResearch")
      .withIndex("by_grievance", (q) => q.eq("grievanceId", grievanceId))
      .first(),
});
