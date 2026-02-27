import {
  createBrowserClient,
  createServerClient,
  type CookieOptions,
} from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";
import { cookies } from "next/headers";

import type { Database } from "./types";

let browserClient: SupabaseClient<Database> | null = null;

const getSupabaseUrl = (): string => {
  const value = process.env.NEXT_PUBLIC_SUPABASE_URL;

  if (!value) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL. Add it to your .env.local file.",
    );
  }

  return value;
};

const getSupabaseAnonKey = (): string => {
  const value = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!value) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_ANON_KEY. Add it to your .env.local file.",
    );
  }

  return value;
};

export const createClientSupabaseClient = (): SupabaseClient<Database> => {
  if (browserClient) {
    return browserClient;
  }

  browserClient = createBrowserClient<Database>(
    getSupabaseUrl(),
    getSupabaseAnonKey(),
  );

  return browserClient;
};

export const createServerSupabaseClient = async (): Promise<
  SupabaseClient<Database>
> => {
  const cookieStore = await cookies();

  return createServerClient<Database>(getSupabaseUrl(), getSupabaseAnonKey(), {
    cookies: {
      get(name: string): string | undefined {
        return cookieStore.get(name)?.value;
      },
      set(name: string, value: string, options: CookieOptions): void {
        try {
          cookieStore.set({ name, value, ...options });
        } catch {
          // Server Components can be read-only for cookies in some render contexts.
        }
      },
      remove(name: string, options: CookieOptions): void {
        try {
          cookieStore.set({ name, value: "", ...options, maxAge: 0 });
        } catch {
          // Server Components can be read-only for cookies in some render contexts.
        }
      },
    },
  });
};
