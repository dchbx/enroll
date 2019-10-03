// Minimum of what the Creation form needs to draw itself

export interface QleKindSortingOrderResource {

    effective_on_kinds: Array<string>;
    title: string;
    tool_tip: string | null;
    action_kind: string | null;
    reason: string | null;
    market_kind: string;
    pre_event_sep_in_days: number;
    post_event_sep_in_days: number;
    is_self_attested: boolean;
    date_options_available: boolean;
    ordinal_position: number;
    event_kind_label: string;
    start_on: string;
    is_active:  boolean;
    event_on: string;
    coverage_effective_on: string;
    end_on: string;
    visibility: string;
    questions: Array<string>;
    pre_event_sep_eligibility:number,
    post_event_sep_eligibility:number,
    available_in_system_from: string,  
    available_in_system_until: string

  }
  

  // The maximum data being sent to the server
  
  export interface QleKindSortingOrderRequest {
    _id: string;
    effective_on_kinds: Array<string>;
    title: string;
    tool_tip: string | null;
    action_kind: string | null;
    reason: string | null;
    market_kind: string;
    pre_event_sep_in_days: number;
    post_event_sep_in_days: number;
    is_self_attested: boolean;
    date_options_available: boolean;
    ordinal_position: number;
    event_kind_label: string;
    is_active:  boolean;
    event_on: string;
    coverage_effective_on: string;
    start_on: string;
    end_on: string;
    visibility: string;
  }
  