import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const insert = mutation({
  args: {
    grievanceId: v.string(),
    transcript: v.any(),
    verdict: v.optional(v.any()),
    plaintiffArguments: v.array(v.string()),
    defendantArguments: v.array(v.string()),
    comicBeats: v.array(v.string()),
    durationSeconds: v.float64(),
    finisherType: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("episodes", {
      grievanceId: args.grievanceId,
      transcript: args.transcript,
      verdict: args.verdict,
      plaintiffArguments: args.plaintiffArguments,
      defendantArguments: args.defendantArguments,
      comicBeats: args.comicBeats,
      generatedAt: Date.now(),
      durationSeconds: args.durationSeconds,
      viewCount: 0,
      finisherType: args.finisherType,
    });
  },
});

export const getById = query({
  args: { id: v.id("episodes") },
  handler: async (ctx, { id }) => {
    return await ctx.db.get(id);
  },
});

export const listRecent = query({
  args: { limit: v.optional(v.float64()) },
  handler: async (ctx, { limit }) => {
    const docs = await ctx.db.query("episodes").withIndex("by_generated").order("desc").take(Number(limit ?? 50));
    return docs;
  },
});

export const incrementViewCount = mutation({
  args: { id: v.id("episodes") },
  handler: async (ctx, { id }) => {
    const doc = await ctx.db.get(id);
    if (!doc) return null;
    await ctx.db.patch(id, { viewCount: doc.viewCount + 1 });
    return doc.viewCount + 1;
  },
});
