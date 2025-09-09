import React, { useState, useRef, useEffect } from 'react';
import styled from 'styled-components';
import { useApi } from '../context/ApiContext';
import { Send, Bot, User, Loader } from 'lucide-react';

const Container = styled.div`
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: #0d1117;
`;

const Header = styled.div`
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #30363d;
  background: #161b22;
`;

const Title = styled.h1`
  font-size: 1.5rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0 0 0.5rem 0;
`;

const Subtitle = styled.p`
  color: #7d8590;
  margin: 0;
  font-size: 0.875rem;
`;

const ChatArea = styled.div`
  flex: 1;
  overflow-y: auto;
  padding: 1rem 2rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
`;

const Message = styled.div`
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  margin-bottom: 1rem;
  max-width: 80%;
  ${props => props.isUser && 'margin-left: auto; flex-direction: row-reverse;'}
`;

const Avatar = styled.div`
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: ${props => props.isUser ? '#1f6feb' : '#238636'};
  color: white;
  flex-shrink: 0;

  svg {
    width: 16px;
    height: 16px;
  }
`;

const MessageBubble = styled.div`
  background: ${props => props.isUser ? '#1f6feb' : '#21262d'};
  border: 1px solid ${props => props.isUser ? '#1f6feb' : '#30363d'};
  border-radius: 12px;
  padding: 0.75rem 1rem;
  color: #f0f6fc;
  line-height: 1.5;
  word-wrap: break-word;
  position: relative;
  
  ${props => props.isUser && `
    &::before {
      content: '';
      position: absolute;
      right: -8px;
      top: 12px;
      width: 0;
      height: 0;
      border: 8px solid transparent;
      border-left-color: #1f6feb;
    }
  `}
  
  ${props => !props.isUser && `
    &::before {
      content: '';
      position: absolute;
      left: -8px;
      top: 12px;
      width: 0;
      height: 0;
      border: 8px solid transparent;
      border-right-color: #21262d;
    }
  `}
`;

const MessageTime = styled.div`
  font-size: 0.75rem;
  color: #7d8590;
  margin-top: 0.25rem;
  ${props => props.isUser && 'text-align: right;'}
`;

const InputArea = styled.div`
  padding: 1rem 2rem;
  border-top: 1px solid #30363d;
  background: #161b22;
`;

const InputContainer = styled.div`
  display: flex;
  gap: 0.75rem;
  align-items: flex-end;
`;

const Input = styled.textarea`
  flex: 1;
  background: #0d1117;
  border: 1px solid #30363d;
  border-radius: 8px;
  padding: 0.75rem;
  color: #f0f6fc;
  font-size: 0.875rem;
  line-height: 1.4;
  resize: none;
  min-height: 40px;
  max-height: 120px;
  
  &:focus {
    outline: none;
    border-color: #58a6ff;
  }
  
  &::placeholder {
    color: #7d8590;
  }
`;

const SendButton = styled.button`
  background: #238636;
  border: 1px solid #238636;
  border-radius: 6px;
  padding: 0.75rem;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  
  &:hover:not(:disabled) {
    background: #2ea043;
    border-color: #2ea043;
  }
  
  &:disabled {
    background: #30363d;
    border-color: #30363d;
    cursor: not-allowed;
    opacity: 0.5;
  }
  
  svg {
    width: 16px;
    height: 16px;
  }
`;

const LoadingMessage = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #7d8590;
  font-style: italic;
  margin: 1rem 0;
`;

const ErrorMessage = styled.div`
  background: #7f1d1d;
  border: 1px solid #f87171;
  border-radius: 6px;
  padding: 1rem;
  color: #fecaca;
  margin: 1rem 0;
`;

const EmptyState = styled.div`
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  color: #7d8590;
  gap: 1rem;
`;

const SuggestedQuestions = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 0.75rem;
  margin-top: 1rem;
  max-width: 600px;
`;

const SuggestionCard = styled.button`
  background: #21262d;
  border: 1px solid #30363d;
  border-radius: 8px;
  padding: 1rem;
  text-align: left;
  color: #f0f6fc;
  cursor: pointer;
  transition: all 0.2s ease;
  
  &:hover {
    background: #30363d;
    border-color: #58a6ff;
  }
  
  .question {
    font-weight: 500;
    margin-bottom: 0.25rem;
  }
  
  .description {
    font-size: 0.875rem;
    color: #7d8590;
  }
`;

const Chat = () => {
  const { loading, error, chatWithAI } = useApi();
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const chatAreaRef = useRef(null);
  const inputRef = useRef(null);

  const suggestedQuestions = [
    {
      question: "What is the current status of my node?",
      description: "Get an overview of your node's health and sync status"
    },
    {
      question: "Are there any issues I should be concerned about?",
      description: "Check for potential problems or warnings"
    },
    {
      question: "How is my node's performance?",
      description: "Analyze performance metrics and peer connectivity"
    },
    {
      question: "What maintenance should I perform?",
      description: "Get recommendations for node maintenance"
    }
  ];

  useEffect(() => {
    // Scroll to bottom when new messages are added
    if (chatAreaRef.current) {
      chatAreaRef.current.scrollTop = chatAreaRef.current.scrollHeight;
    }
  }, [messages, sending]);

  const handleSend = async () => {
    if (!input.trim() || sending) return;

    const userMessage = {
      id: Date.now(),
      text: input.trim(),
      isUser: true,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setSending(true);

    try {
      const response = await chatWithAI(userMessage.text);
      
      const aiMessage = {
        id: Date.now() + 1,
        text: response.response || 'I apologize, but I couldn\'t generate a response.',
        isUser: false,
        timestamp: new Date(),
        latency: response.latency_ms
      };

      setMessages(prev => [...prev, aiMessage]);
    } catch (err) {
      console.error('Chat failed:', err);
      const errorMessage = {
        id: Date.now() + 1,
        text: `Sorry, I encountered an error: ${err.message}`,
        isUser: false,
        timestamp: new Date(),
        isError: true
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setSending(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleSuggestion = (question) => {
    setInput(question);
    inputRef.current?.focus();
  };

  return (
    <Container>
      <Header>
        <Title>AI Chat</Title>
        <Subtitle>Ask questions about your Cintara node status, performance, and diagnostics</Subtitle>
      </Header>

      <ChatArea ref={chatAreaRef}>
        {messages.length === 0 && !sending ? (
          <EmptyState>
            <Bot size={48} />
            <div>
              <h3>Start a conversation</h3>
              <p>Ask me anything about your Cintara blockchain node</p>
            </div>
            
            <SuggestedQuestions>
              {suggestedQuestions.map((item, index) => (
                <SuggestionCard 
                  key={index}
                  onClick={() => handleSuggestion(item.question)}
                >
                  <div className="question">{item.question}</div>
                  <div className="description">{item.description}</div>
                </SuggestionCard>
              ))}
            </SuggestedQuestions>
          </EmptyState>
        ) : (
          <>
            {messages.map((message) => (
              <Message key={message.id} isUser={message.isUser}>
                <Avatar isUser={message.isUser}>
                  {message.isUser ? <User /> : <Bot />}
                </Avatar>
                <div>
                  <MessageBubble 
                    isUser={message.isUser}
                    style={message.isError ? { background: '#7f1d1d', borderColor: '#f87171' } : {}}
                  >
                    {message.text}
                  </MessageBubble>
                  <MessageTime isUser={message.isUser}>
                    {message.timestamp.toLocaleTimeString()}
                    {message.latency && ` • ${message.latency}ms`}
                  </MessageTime>
                </div>
              </Message>
            ))}
            
            {sending && (
              <LoadingMessage>
                <Loader size={16} className="animate-spin" />
                AI is thinking...
              </LoadingMessage>
            )}
          </>
        )}

        {error && (
          <ErrorMessage>
            Error: {error}
          </ErrorMessage>
        )}
      </ChatArea>

      <InputArea>
        <InputContainer>
          <Input
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Ask about your node status, performance, or any blockchain questions..."
            disabled={sending}
          />
          <SendButton 
            onClick={handleSend}
            disabled={!input.trim() || sending}
          >
            {sending ? <Loader className="animate-spin" /> : <Send />}
          </SendButton>
        </InputContainer>
      </InputArea>
    </Container>
  );
};

export default Chat;