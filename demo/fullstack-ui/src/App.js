import * as React from "react";
import { Admin, Resource, fetchUtils  } from 'react-admin';
import authProvider from './authProvider';

import dataProvider from './dataProvider.ts';

import { WansitesList, WansiteEdit } from './wanSite';


const fetchJson = (url, options = {}) => {
  if (!options.headers) {
      options.headers = new Headers({ Accept: 'application/json' });
  }
  const username = localStorage.getItem('username');
  const password = localStorage.getItem('password');
  const basic_auth_header = "Basic " + btoa(username+":"+password)

  options.headers.set('Authorization', basic_auth_header);
  return fetchUtils.fetchJson(url, options);
}


const myDataProvider = dataProvider('http://127.0.0.1:8000',fetchJson);
//const myDataProvider = dataProvider('http://192.168.0.12:12345',fetchJson);


const App = () => (
    <Admin authProvider={authProvider} dataProvider={myDataProvider}>
      <Resource name="wan_sites" options={{ label: 'Wan Sites' }} list={WansitesList} edit={WansiteEdit} />
    </Admin>
);

export default App;