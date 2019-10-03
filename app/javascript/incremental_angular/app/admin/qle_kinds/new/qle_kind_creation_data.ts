// Minimum of what the Creation form needs to draw itself

  export interface QleKindCreationResource {
    effective_on_kinds: Array<string>;
    title: string;
    tool_tip: string | null;
    reason: string | null;
    market_kind: string;
    is_self_attested: boolean;
    visible_to_customer: boolean;
    date_options_available: boolean;
    ordinal_position: number;
    event_kind_label: string;
    start_on: string;
    is_active: boolean;
    event_on: string;
    coverage_effective_on: string;
    end_on: string;
    pre_event_sep_eligibility: number;
    post_event_sep_eligibility: number;
    available_in_system_from: string;  
    available_in_system_until: string;
  }

  // The maximum data being sent to the server
  interface ResponseCreationRequest {
    content: string;
    action_to_take: string;
  }

  interface QuestionCreationRequest {
    content: string;
    responses: Array<ResponseCreationRequest>;
  }
  
  export interface QleKindCreationRequest {
    effective_on_kinds: Array<string>;
    title: string;
    tool_tip: string | null;
    reason: string | null;
    market_kind: string;
    pre_event_sep_in_days: number;
    post_event_sep_in_days: number;
    is_self_attested: boolean;
    visible_to_customer: boolean;
    date_options_available: boolean;
    ordinal_position: number;
    event_kind_label: string;
    is_active:  boolean;
    event_on: string;
    coverage_effective_on: string;
    start_on: string;
    end_on: string;
    questions: Array<QuestionCreationRequest>;
  }
  