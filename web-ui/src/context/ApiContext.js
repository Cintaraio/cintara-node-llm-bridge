import React, { createContext, useContext, useState, useCallback } from 'react';
import axios from 'axios';

const ApiContext = createContext();

export const useApi = () => {
  const context = useContext(ApiContext);
  if (!context) {
    throw new Error('useApi must be used within an ApiProvider');
  }
  return context;
};

const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';

export const ApiProvider = ({ children }) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const apiCall = useCallback(async (endpoint, options = {}) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await axios({
        url: `${API_BASE_URL}${endpoint}`,
        timeout: 30000,
        ...options
      });
      return response.data;
    } catch (err) {
      const errorMessage = err.response?.data?.detail || err.message || 'API call failed';
      setError(errorMessage);
      throw new Error(errorMessage);
    } finally {
      setLoading(false);
    }
  }, []);

  // Health check
  const checkHealth = useCallback(() => {
    return apiCall('/health');
  }, [apiCall]);

  // Node status
  const getNodeStatus = useCallback(() => {
    return apiCall('/node/status');
  }, [apiCall]);

  // Node diagnostics
  const diagnoseNode = useCallback(() => {
    return apiCall('/node/diagnose', { method: 'POST' });
  }, [apiCall]);

  // Chat with AI
  const chatWithAI = useCallback((message) => {
    return apiCall('/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      data: { message }
    });
  }, [apiCall]);

  // Get node peers
  const getNodePeers = useCallback(() => {
    return apiCall('/node/peers');
  }, [apiCall]);

  // Analyze logs
  const analyzeLogs = useCallback(() => {
    return apiCall('/node/logs');
  }, [apiCall]);

  // Analyze block transactions
  const analyzeBlockTransactions = useCallback((blockHeight) => {
    return apiCall(`/node/transactions/${blockHeight}`);
  }, [apiCall]);

  // Debug LLM
  const debugLLM = useCallback(() => {
    return apiCall('/debug/llm');
  }, [apiCall]);

  const value = {
    loading,
    error,
    setError,
    checkHealth,
    getNodeStatus,
    diagnoseNode,
    chatWithAI,
    getNodePeers,
    analyzeLogs,
    analyzeBlockTransactions,
    debugLLM
  };

  return (
    <ApiContext.Provider value={value}>
      {children}
    </ApiContext.Provider>
  );
};