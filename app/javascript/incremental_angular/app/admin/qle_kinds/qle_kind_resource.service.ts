import { Injectable, ClassProvider } from '@angular/core';
import { HttpClient, HttpResponse } from '@angular/common/http';
import { Observable } from "rxjs";

@Injectable()
export class QleKindResourceService {
  constructor(private http: HttpClient) { }

  public submitDeactivate(post_uri: string, obj_data : object) : Observable<HttpResponse<any>> {
    var json = JSON.stringify({ data: obj_data });
    return this.http.put(
      post_uri + ".json",
      json,
      {
        headers : {
          'Content-Type': 'application/json',
        },
        observe: "response",
        withCredentials: true
      }
    );
  };

  public submitCreate(post_uri: string, obj_data : object) : Observable<HttpResponse<any>> {
    var json = JSON.stringify({ data: obj_data });
    return this.http.post(
      `${post_uri}.json`,
      json,
      {
        headers : {
          'Content-Type': 'application/json',
        },
        observe: "response",
        withCredentials: true
      }
    );
  };

  public submitSortingOrder(post_uri: string, obj_data : object) : Observable<HttpResponse<any>> {
    var json = JSON.stringify({ data: obj_data });
    return this.http.post(
      post_uri,
      json,
      {
        headers : {
          'Content-Type': 'application/json',
        },
        observe: "response",
        withCredentials: true
      }
    );
  };

  public submitEdit(post_uri: string, obj_data : object) : Observable<HttpResponse<any>> {
    var json = JSON.stringify({ data: obj_data });
    console.log(json)
    return this.http.put(
      post_uri,
      json,
      {
        headers : {
          'Content-Type': 'application/json',
        },
        observe: "response",
        withCredentials: true
      }
    );
  };

  static provides(token: string) : ClassProvider {
    return {provide: token, useClass: QleKindResourceService}
  }
}