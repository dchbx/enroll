import { Observable } from "rxjs";

export interface BrokerAgencyProfileCreationService {
  submitCreate(post_uri: string, obj_data : object): Observable<object>;
}