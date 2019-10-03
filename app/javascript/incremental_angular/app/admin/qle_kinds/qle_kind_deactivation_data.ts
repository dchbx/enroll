// Minimum of what the deactivation form needs to draw itself

export interface QleKindDeactivationResource {
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
  event_kind_label: string;
  start_on: string;
}

// The maximum data being sent to the server

export interface QleKindDeactivationRequest {
  _id: string;
  end_on: string;
}
