// Minimum of what the Edit form needs to draw itself

export interface QleKindEditResource {
  _id: string;
  effective_on_kinds: Array<string>;
  title: string;
  tool_tip: string | null;
  reason: string | null;
  market_kind: string;
  pre_event_sep_in_days: number;
  post_event_sep_in_days: number;
  is_self_attested: boolean;
  date_options_available: boolean;
  visible_to_customer: boolean;
  ordinal_position: number;
  event_kind_label: string;
  custom_qle_questions: Array<string>;
  start_on: string;
  is_active:  boolean;
  event_on: string;
  coverage_effective_on: string;
  end_on: string;
  visibility: string;
}

interface ResponseCreationRequest {
  content: string;
  action_to_take: string;
}

interface QuestionCreationRequest {
  content: string;
  responses: Array<ResponseCreationRequest>;
}

// The maximum data being sent to the server
// edi_code cannot be edited
  
export interface QleKindUpdateRequest {
  _id: string;
  effective_on_kinds: Array<string>;
  title: string;
  tool_tip: string | null;
  reason: string | null;
  market_kind: string;
  pre_event_sep_in_days: number;
  post_event_sep_in_days: number;
  is_self_attested: boolean;
  date_options_available: boolean;
  visible_to_customer: boolean;
  ordinal_position: number;
  event_kind_label: string;
  is_active:  boolean;
  event_on: string;
  coverage_effective_on: string;
  start_on: string;
  end_on: string;
  visibility: string;
  custom_qle_questions: Array<QuestionCreationRequest>;

}
  