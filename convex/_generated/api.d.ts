/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type * as agents_deadpoolNPH from "../agents/deadpoolNPH.js";
import type * as agents_jasonTodd from "../agents/jasonTodd.js";
import type * as agents_judgeJerry from "../agents/judgeJerry.js";
import type * as agents_mattMurdock from "../agents/mattMurdock.js";
import type * as episodes from "../episodes.js";
import type * as grievances from "../grievances.js";
import type * as guestCharacters from "../guestCharacters.js";
import type * as research from "../research.js";
import type * as researchData from "../researchData.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  "agents/deadpoolNPH": typeof agents_deadpoolNPH;
  "agents/jasonTodd": typeof agents_jasonTodd;
  "agents/judgeJerry": typeof agents_judgeJerry;
  "agents/mattMurdock": typeof agents_mattMurdock;
  episodes: typeof episodes;
  grievances: typeof grievances;
  guestCharacters: typeof guestCharacters;
  research: typeof research;
  researchData: typeof researchData;
}>;

/**
 * A utility for referencing Convex functions in your app's public API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;

/**
 * A utility for referencing Convex functions in your app's internal API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = internal.myModule.myFunction;
 * ```
 */
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;

export declare const components: {};
