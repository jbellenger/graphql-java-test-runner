import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import reportWebVitals from './reportWebVitals';
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Link,
  BrowserRouter,
  Routes,
} from "react-router-dom";
import { Dashboard } from './Views/Dashboard';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
 /* <React.StrictMode>
    <App />
 </React.StrictMode>
 */
<React.StrictMode>
  <BrowserRouter>
    <Routes>
      <Route path="/graphql-java-test-runner" element={<Dashboard/>}/>
    </Routes>
  </BrowserRouter>
</React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
