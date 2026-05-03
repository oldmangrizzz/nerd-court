"use node";
/**
 * Canon research pipeline.
 *
 * Inputs (per blueprint §4.1): plaintiff, defendant, grievanceText. Nothing
 * else from the user.
 *
 * Outputs (per blueprint §4.2 and §6 canonResearch table):
 *  - sources[]: web sources used (Wikipedia, Fandom, YouTube)
 *  - keyFacts[]: top canon facts surfaced from the case
 *  - plaintiffEvidence[] / defendantEvidence[]: side-specific evidence
 *  - cast[]: every speaker for the trial (4 staff + plaintiff(s) + defendant(s)
 *    + 0-3 witnesses), each with a YouTube reference clip query for F5-XTTS
 *
 * Search backends are free and key-less:
 *  - Wikipedia REST API (en.wikipedia.org/api/rest_v1)
 *  - Fandom search API (community.fandom.com/api.php)
 *  - YouTube search via yt-dlp's ytsearch1 directive, executed by the F5-TTS
 *    GPU server when /v1/voices/register is called with `youtube_url:
 *    "ytsearch1:..."`.
 */
import { action } from "./_generated/server";
import { v } from "convex/values";
import { api } from "./_generated/api";

type Source = {
  id: string;
  title: string;
  url: string;
  excerpt: string;
  origin: "wikipedia" | "fandom" | "youtube";
};

type CastMember = {
  voiceId: string;
  displayName: string;
  role:
    | "plaintiff_lawyer"
    | "defense_lawyer"
    | "judge"
    | "announcer"
    | "plaintiff"
    | "defendant"
    | "witness_plaintiff"
    | "witness_defense";
  systemPrompt: string;
  voiceQuery: string; // yt-dlp ytsearch1 directive
  voiceClipStart: number;
  voiceClipEnd: number;
  voiceRefText: string;
};

const STAFF_VOICE_QUERIES: Record<string, { query: string; refText: string }> = {
  jason_todd: {
    query:
      "ytsearch1:Jason Todd Red Hood Arkham Knight angry monologue gameplay",
    refText: "",
  },
  matt_murdock: {
    query: "ytsearch1:Matt Murdock Daredevil Netflix courtroom closing argument",
    refText: "",
  },
  judge_jerry: {
    query: "ytsearch1:Jerry Springer final thought monologue full episode",
    refText: "",
  },
  deadpool_nph: {
    query:
      "ytsearch1:Neil Patrick Harris Dr Horrible Sing Along Blog narration",
    refText: "",
  },
};

async function searchWikipedia(query: string): Promise<Source[]> {
  const url = new URL("https://en.wikipedia.org/w/api.php");
  url.searchParams.set("action", "query");
  url.searchParams.set("list", "search");
  url.searchParams.set("srsearch", query);
  url.searchParams.set("srlimit", "5");
  url.searchParams.set("format", "json");
  url.searchParams.set("origin", "*");
  const resp = await fetch(url.toString(), {
    headers: { "User-Agent": "NerdCourt/1.0 (canon-research)" },
  });
  if (!resp.ok) return [];
  const data: any = await resp.json();
  const hits = data?.query?.search ?? [];
  return hits.map((h: any) => ({
    id: `wikipedia:${h.pageid}`,
    title: h.title,
    url: `https://en.wikipedia.org/?curid=${h.pageid}`,
    excerpt: (h.snippet ?? "")
      .replace(/<[^>]+>/g, "")
      .replace(/&quot;/g, '"')
      .slice(0, 400),
    origin: "wikipedia" as const,
  }));
}

async function searchFandom(query: string): Promise<Source[]> {
  // Fandom's unified search endpoint covers every wiki under fandom.com.
  const url = new URL("https://community.fandom.com/api.php");
  url.searchParams.set("action", "query");
  url.searchParams.set("list", "search");
  url.searchParams.set("srsearch", query);
  url.searchParams.set("srlimit", "5");
  url.searchParams.set("format", "json");
  url.searchParams.set("origin", "*");
  const resp = await fetch(url.toString(), {
    headers: { "User-Agent": "NerdCourt/1.0 (canon-research)" },
  });
  if (!resp.ok) return [];
  const data: any = await resp.json();
  const hits = data?.query?.search ?? [];
  return hits.map((h: any) => ({
    id: `fandom:${h.pageid}`,
    title: h.title,
    url: `https://community.fandom.com/wiki/${encodeURIComponent(h.title.replace(/ /g, "_"))}`,
    excerpt: (h.snippet ?? "")
      .replace(/<[^>]+>/g, "")
      .replace(/&quot;/g, '"')
      .slice(0, 400),
    origin: "fandom" as const,
  }));
}

function buildGuestSystemPrompt(
  name: string,
  universe: string,
  role: CastMember["role"],
  evidenceSummary: string,
): string {
  return `You are ${name}, called as a ${role.replace("_", " ")} in Nerd Court.

UNIVERSE: ${universe}
CONTEXT: ${evidenceSummary}

RULES:
- Stay 100% in character. Speak with ${name}'s established speech patterns, vocabulary, and worldview.
- Reference your own canon directly. Cite specific issues, episodes, or scenes when accurate.
- 2-4 sentences per turn. Punchy. No filibuster.
- This is parody — you are allowed to be biased toward your own universe.`;
}

export const runFullResearch = action({
  args: {
    grievanceId: v.string(),
    plaintiff: v.string(),
    defendant: v.string(),
    grievanceText: v.string(),
  },
  handler: async (
    ctx,
    { grievanceId, plaintiff, defendant, grievanceText },
  ): Promise<{
    sources: Source[];
    keyFacts: string[];
    plaintiffEvidence: string[];
    defendantEvidence: string[];
    cast: CastMember[];
  }> => {
    const baseQuery = `${plaintiff} ${defendant} ${grievanceText}`;
    const plaintiffQ = `${plaintiff} canon backstory speech personality`;
    const defendantQ = `${defendant} canon backstory speech personality`;

    const [wikiCase, wikiPlaintiff, wikiDefendant, fandomPlaintiff, fandomDefendant] =
      await Promise.all([
        searchWikipedia(baseQuery),
        searchWikipedia(plaintiffQ),
        searchWikipedia(defendantQ),
        searchFandom(plaintiffQ),
        searchFandom(defendantQ),
      ]);

    const allSources: Source[] = [
      ...wikiCase,
      ...wikiPlaintiff,
      ...wikiDefendant,
      ...fandomPlaintiff,
      ...fandomDefendant,
    ];

    const plaintiffEvidence = [...wikiPlaintiff, ...fandomPlaintiff]
      .map((s) => `${s.title}: ${s.excerpt}`)
      .filter((s) => s.length > 30)
      .slice(0, 6);
    const defendantEvidence = [...wikiDefendant, ...fandomDefendant]
      .map((s) => `${s.title}: ${s.excerpt}`)
      .filter((s) => s.length > 30)
      .slice(0, 6);
    const keyFacts = wikiCase
      .map((s) => `${s.title}: ${s.excerpt}`)
      .filter((s) => s.length > 30)
      .slice(0, 6);

    // Persist research (mutation runs inside the action)
    await ctx.runMutation(api.research.saveResearch, {
      grievanceId,
      sources: allSources,
      keyFacts,
      plaintiffEvidence,
      defendantEvidence,
    });

    // Universe inference: pick the most repeated source origin/title token.
    const inferUniverse = (
      who: string,
      hits: Source[],
    ): string => {
      for (const h of hits) {
        const lower = (h.title + " " + h.excerpt).toLowerCase();
        if (lower.includes("dc comics") || lower.includes("batman") || lower.includes("gotham")) return "DC Comics";
        if (lower.includes("marvel")) return "Marvel Comics";
        if (lower.includes("star wars")) return "Star Wars";
        if (lower.includes("doctor who")) return "Doctor Who";
        if (lower.includes("harry potter")) return "Harry Potter";
      }
      return who;
    };

    const plaintiffUniverse = inferUniverse(plaintiff, [...wikiPlaintiff, ...fandomPlaintiff]);
    const defendantUniverse = inferUniverse(defendant, [...wikiDefendant, ...fandomDefendant]);

    const plaintiffEvidenceSummary = plaintiffEvidence.slice(0, 2).join(" | ");
    const defendantEvidenceSummary = defendantEvidence.slice(0, 2).join(" | ");

    const staffPrompts = {
      jason_todd: (await import("./agents/jasonTodd")).SYSTEM_PROMPT,
      matt_murdock: (await import("./agents/mattMurdock")).SYSTEM_PROMPT,
      judge_jerry: (await import("./agents/judgeJerry")).SYSTEM_PROMPT,
      deadpool_nph: (await import("./agents/deadpoolNPH")).SYSTEM_PROMPT,
    };

    const staffCast: CastMember[] = [
      {
        voiceId: "jason_todd",
        displayName: "Jason Todd",
        role: "plaintiff_lawyer",
        systemPrompt: staffPrompts.jason_todd,
        voiceQuery: STAFF_VOICE_QUERIES.jason_todd.query,
        voiceClipStart: 0,
        voiceClipEnd: 5,
        voiceRefText: STAFF_VOICE_QUERIES.jason_todd.refText,
      },
      {
        voiceId: "matt_murdock",
        displayName: "Matt Murdock",
        role: "defense_lawyer",
        systemPrompt: staffPrompts.matt_murdock,
        voiceQuery: STAFF_VOICE_QUERIES.matt_murdock.query,
        voiceClipStart: 0,
        voiceClipEnd: 5,
        voiceRefText: STAFF_VOICE_QUERIES.matt_murdock.refText,
      },
      {
        voiceId: "judge_jerry",
        displayName: "Judge Jerry Springer",
        role: "judge",
        systemPrompt: staffPrompts.judge_jerry,
        voiceQuery: STAFF_VOICE_QUERIES.judge_jerry.query,
        voiceClipStart: 0,
        voiceClipEnd: 5,
        voiceRefText: STAFF_VOICE_QUERIES.judge_jerry.refText,
      },
      {
        voiceId: "deadpool_nph",
        displayName: "Deadpool (as NPH)",
        role: "announcer",
        systemPrompt: staffPrompts.deadpool_nph,
        voiceQuery: STAFF_VOICE_QUERIES.deadpool_nph.query,
        voiceClipStart: 0,
        voiceClipEnd: 5,
        voiceRefText: STAFF_VOICE_QUERIES.deadpool_nph.refText,
      },
    ];

    const guestPlaintiffId = `plaintiff_${plaintiff.replace(/\W+/g, "_").toLowerCase()}`;
    const guestDefendantId = `defendant_${defendant.replace(/\W+/g, "_").toLowerCase()}`;

    const guestCast: CastMember[] = [
      {
        voiceId: guestPlaintiffId,
        displayName: plaintiff,
        role: "plaintiff",
        systemPrompt: buildGuestSystemPrompt(
          plaintiff,
          plaintiffUniverse,
          "plaintiff",
          plaintiffEvidenceSummary,
        ),
        voiceQuery: `ytsearch1:${plaintiff} ${plaintiffUniverse} voice scene clip`,
        voiceClipStart: 0,
        voiceClipEnd: 5,
        voiceRefText: "",
      },
      {
        voiceId: guestDefendantId,
        displayName: defendant,
        role: "defendant",
        systemPrompt: buildGuestSystemPrompt(
          defendant,
          defendantUniverse,
          "defendant",
          defendantEvidenceSummary,
        ),
        voiceQuery: `ytsearch1:${defendant} ${defendantUniverse} voice scene clip`,
        voiceClipStart: 0,
        voiceClipEnd: 5,
        voiceRefText: "",
      },
    ];

    return {
      sources: allSources,
      keyFacts,
      plaintiffEvidence,
      defendantEvidence,
      cast: [...staffCast, ...guestCast],
    };
  },
});
