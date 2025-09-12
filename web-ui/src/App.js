import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import styled from 'styled-components';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import Chat from './pages/Chat';
import ChatOnly from './pages/ChatOnly';
import NodeStatus from './pages/NodeStatus';
import Diagnostics from './pages/Diagnostics';
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
          <Route path="/*" element={
            <AppContainer>
              <Sidebar />
              <MainContent>
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/chat" element={<Chat />} />
                  <Route path="/status" element={<NodeStatus />} />
                  <Route path="/diagnostics" element={<Diagnostics />} />
                </Routes>
              </MainContent>
            </AppContainer>
          } />
        </Routes>
      </Router>
    </ApiProvider>
  );
}

export default App;