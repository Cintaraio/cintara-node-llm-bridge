import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import styled from 'styled-components';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import Chat from './pages/Chat';
import ChatOnly from './pages/ChatOnly';
import NodeStatus from './pages/NodeStatus';
import Diagnostics from './pages/Diagnostics';
import TaxBit from './pages/TaxBit';
import { ApiProvider } from './context/ApiContext';

const AppContainer = styled.div`
  display: flex;
  height: 100vh;
  background: #0a0b0f;
  color: #e1e4e8;
`;

const MainContent = styled.div`
  flex: 1;
  overflow: auto;
  background: #0d1117;
`;

function App() {
  return (
    <ApiProvider>
      <Router>
        <Routes>
          <Route path="/chat-only" element={<ChatOnly />} />
          <Route path="/" element={
            <AppContainer>
              <Sidebar />
              <MainContent>
                <Dashboard />
              </MainContent>
            </AppContainer>
          } />
          <Route path="/chat" element={
            <AppContainer>
              <Sidebar />
              <MainContent>
                <Chat />
              </MainContent>
            </AppContainer>
          } />
          <Route path="/status" element={
            <AppContainer>
              <Sidebar />
              <MainContent>
                <NodeStatus />
              </MainContent>
            </AppContainer>
          } />
          <Route path="/diagnostics" element={
            <AppContainer>
              <Sidebar />
              <MainContent>
                <Diagnostics />
              </MainContent>
            </AppContainer>
          } />
          <Route path="/taxbit" element={
            <AppContainer>
              <Sidebar />
              <MainContent>
                <TaxBit />
              </MainContent>
            </AppContainer>
          } />
        </Routes>
      </Router>
    </ApiProvider>
  );
}

export default App;