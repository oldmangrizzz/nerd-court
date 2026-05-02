import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const submit = mutation({
  args: {
    plaintiff: v.string(),
    defendant: v.string(),
    grievanceText: v.string(),
    franchise: v.string(),
    guestPlaintiffId: v.optional(v.string()),
    guestDefendantId: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("grievances", {
      ...args,
      submittedAt: Date.now(),
      status: "pending",
    });
  },
});

export const listPending = query({
  args: {},
  handler: async (ctx) => {
    return await ctx.db.query("grievances").withIndex("by_status", (q) => q.eq("status", "pending")).collect();
  },
});

export const setStatus = mutation({
  args: { id: v.id("grievances"), status: v.union(v.literal("pending"), v.literal("inTrial"), v.literal("decided")) },
  handler: async (ctx, { id, status }) => {
    await ctx.db.patch(id, { status });
  },
});

export const getById = query({
  args: { id: v.id("grievances") },
  handler: async (ctx, { id }) => {
    return await ctx.db.get(id);
  },
});
