import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  grievances: defineTable({
    plaintiff: v.string(),
    defendant: v.string(),
    grievanceText: v.string(),
    submittedBy: v.string(),
    submittedAt: v.float64(),
    status: v.union(
      v.literal("pending"),
      v.literal("inTrial"),
      v.literal("decided"),
    ),
    guestPlaintiffId: v.optional(v.string()),
    guestDefendantId: v.optional(v.string()),
  })
    .index("by_status", ["status"])
    .index("by_submitted", ["submittedAt"]),

  episodes: defineTable({
    grievanceId: v.string(),
    transcript: v.any(),
    verdict: v.optional(v.any()),
    plaintiffArguments: v.array(v.string()),
    defendantArguments: v.array(v.string()),
    comicBeats: v.array(v.string()),
    generatedAt: v.float64(),
    durationSeconds: v.float64(),
    viewCount: v.float64(),
    finisherType: v.optional(v.string()),
  })
    .index("by_grievance", ["grievanceId"])
    .index("by_generated", ["generatedAt"]),

  guestCharacters: defineTable({
    name: v.string(),
    universe: v.string(),
    role: v.string(),
    voiceId: v.string(),
    personalityPrompt: v.string(),
    generatedAt: v.float64(),
    usedInEpisodeIds: v.array(v.string()),
  })
    .index("by_name", ["name"])
    .index("by_universe", ["universe"]),

  canonResearch: defineTable({
    grievanceId: v.string(),
    sources: v.any(),
    keyFacts: v.array(v.string()),
    plaintiffEvidence: v.array(v.string()),
    defendantEvidence: v.array(v.string()),
    researchedAt: v.float64(),
  }).index("by_grievance", ["grievanceId"]),

  characters: defineTable({
    name: v.string(),
    role: v.union(
      v.literal("plaintiffLawyer"),
      v.literal("defenseLawyer"),
      v.literal("judge"),
      v.literal("announcer"),
    ),
    voiceId: v.string(),
    personalityPrompt: v.string(),
    catchphrases: v.array(v.string()),
  }).index("by_role", ["role"]),
});
