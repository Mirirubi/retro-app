export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type SessionPhase = "waiting" | "private" | "collaborative" | "finished";

export type PostItCategory = "keep" | "improve" | "ideas" | "stop";

export interface Database {
  public: {
    Tables: {
      retro_sessions: {
        Row: {
          id: string;
          code: string;
          moderator_id: string;
          phase: SessionPhase;
          created_at: string;
        };
        Insert: {
          id?: string;
          code: string;
          moderator_id: string;
          phase?: SessionPhase;
          created_at?: string;
        };
        Update: {
          id?: string;
          code?: string;
          moderator_id?: string;
          phase?: SessionPhase;
          created_at?: string;
        };
        Relationships: [];
      };
      session_users: {
        Row: {
          id: string;
          session_id: string;
          user_name: string;
          is_completed: boolean;
          is_moderator: boolean;
          joined_at: string;
        };
        Insert: {
          id: string;
          session_id: string;
          user_name: string;
          is_completed?: boolean;
          is_moderator?: boolean;
          joined_at?: string;
        };
        Update: {
          id?: string;
          session_id?: string;
          user_name?: string;
          is_completed?: boolean;
          is_moderator?: boolean;
          joined_at?: string;
        };
        Relationships: [];
      };
      postits: {
        Row: {
          id: string;
          session_id: string;
          user_id: string;
          user_name: string;
          category: PostItCategory;
          text: string;
          position_x: number;
          position_y: number;
          group_id: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          session_id: string;
          user_id: string;
          user_name: string;
          category: PostItCategory;
          text: string;
          position_x?: number;
          position_y?: number;
          group_id?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          session_id?: string;
          user_id?: string;
          user_name?: string;
          category?: PostItCategory;
          text?: string;
          position_x?: number;
          position_y?: number;
          group_id?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: {
      session_phase: SessionPhase;
      postit_category: PostItCategory;
    };
    CompositeTypes: Record<string, never>;
  };
}
