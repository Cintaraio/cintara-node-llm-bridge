import React, { useState, useRef, useEffect } from 'react';
import styled from 'styled-components';
import { useApi } from '../context/ApiContext';
import { Send, Bot, User, Loader, MessageCircle } from 'lucide-react';

const Container = styled.div`
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #0a0b0f 0%, #1a1b23 100%);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
`;

const Header = styled.div`
  padding: 1rem 2rem;
  border-bottom: 1px solid #30363d;
  background: rgba(22, 27, 34, 0.95);
  backdrop-filter: blur(10px);
  display: flex;
  align-items: center;
  gap: 0.75rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
  border-top: 3px solid #58a6ff;
`;

const Logo = styled.div`
  width: 32px;
  height: 32px;
  background: linear-gradient(135deg, #58a6ff 0%, #1f6feb 100%);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(88, 166, 255, 0.3);
`;

const TitleContainer = styled.div`
  display: flex;
  flex-direction: column;
`;

const Title = styled.h1`
  font-size: 1.25rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0;
`;

const Subtitle = styled.p`
  color: #7d8590;
  margin: 0;
  font-size: 0.8rem;
`;

const ChatArea = styled.div`
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
  display: flex;
  flex-direction: column;
  max-width: 800px;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
  
  &::-webkit-scrollbar {
    width: 6px;
  }
  
  &::-webkit-scrollbar-track {
    background: transparent;
  }
  
  &::-webkit-scrollbar-thumb {
    background: #30363d;
    border-radius: 3px;
  }
  
  &::-webkit-scrollbar-thumb:hover {
    background: #484f58;
  }
`;

const Message = styled.div`
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
  ${props => props.isUser && `
    flex-direction: row-reverse;
    margin-left: 2rem;
  `}
  ${props => !props.isUser && `
    margin-right: 2rem;
  `}
`;

const Avatar = styled.div`
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: ${props => props.isUser 
    ? 'linear-gradient(135deg, #58a6ff 0%, #1f6feb 100%)' 
    : 'linear-gradient(135deg, #39d353 0%, #238636 100%)'};
  color: white;
  flex-shrink: 0;
  box-shadow: 0 2px 8px ${props => props.isUser 
    ? 'rgba(88, 166, 255, 0.3)' 
    : 'rgba(57, 211, 83, 0.3)'};

  svg {
    width: 18px;
    height: 18px;
  }
`;

const MessageContent = styled.div`
  flex: 1;
`;

const MessageBubble = styled.div`
  background: ${props => props.isUser 
    ? 'linear-gradient(135deg, #1f6feb 0%, #1a5feb 100%)' 
    : 'rgba(33, 38, 45, 0.8)'};
  border: 1px solid ${props => props.isUser ? 'transparent' : '#30363d'};
  border-radius: 16px;
  padding: 1rem 1.25rem;
  color: #f0f6fc;
  line-height: 1.6;
  word-wrap: break-word;
  position: relative;
  backdrop-filter: blur(10px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  
  ${props => props.isUser && `
    box-shadow: 0 2px 12px rgba(31, 111, 235, 0.2);
  `}
`;

const MessageTime = styled.div`
  font-size: 0.7rem;
  color: #7d8590;
  margin-top: 0.5rem;
  ${props => props.isUser && 'text-align: right;'}
`;

const InputArea = styled.div`
  padding: 1.5rem 2rem 2rem;
  background: rgba(22, 27, 34, 0.95);
  backdrop-filter: blur(10px);
  border-top: 1px solid #30363d;
`;

const InputContainer = styled.div`
  display: flex;
  gap: 0.75rem;
  align-items: flex-end;
  max-width: 800px;
  margin: 0 auto;
`;

const Input = styled.textarea`
  flex: 1;
  background: #0d1117;
  border: 2px solid #30363d;
  border-radius: 12px;
  padding: 1rem 1.25rem;
  color: #f0f6fc;
  font-size: 0.9rem;
  line-height: 1.5;
  resize: none;
  min-height: 50px;
  max-height: 120px;
  transition: all 0.2s ease;
  
  &:focus {
    outline: none;
    border-color: #58a6ff;
    box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.1);
  }
  
  &::placeholder {
    color: #7d8590;
  }
`;

const SendButton = styled.button`
  background: linear-gradient(135deg, #238636 0%, #2ea043 100%);
  border: none;
  border-radius: 10px;
  padding: 1rem;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(35, 134, 54, 0.3);
  
  &:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(35, 134, 54, 0.4);
  }
  
  &:disabled {
    background: #30363d;
    cursor: not-allowed;
    opacity: 0.5;
    transform: none;
    box-shadow: none;
  }
  
  svg {
    width: 18px;
    height: 18px;
  }
`;

const LoadingMessage = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #7d8590;
  font-style: italic;
  margin: 1rem 0;
  justify-content: center;
  
  .spinner {
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
`;

const ErrorMessage = styled.div`
  background: rgba(127, 29, 29, 0.8);
  border: 1px solid #f87171;
  border-radius: 12px;
  padding: 1rem;
  color: #fecaca;
  margin: 1rem 0;
  backdrop-filter: blur(10px);
`;

const EmptyState = styled.div`
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  color: #7d8590;
  gap: 2rem;
  padding: 2rem;
`;

const WelcomeIcon = styled.div`
  width: 80px;
  height: 80px;
  background: linear-gradient(135deg, #58a6ff 0%, #1f6feb 100%);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 24px rgba(88, 166, 255, 0.3);
  
  svg {
    width: 40px;
    height: 40px;
    color: white;
  }
`;

const WelcomeText = styled.div`
  h2 {
    font-size: 2rem;
    font-weight: 700;
    color: #f0f6fc;
    margin: 0 0 0.5rem 0;
  }
  
  p {
    font-size: 1.1rem;
    color: #7d8590;
    margin: 0;
    max-width: 500px;
  }
`;

const SuggestedQuestions = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1rem;
  max-width: 700px;
  width: 100%;
`;

const SuggestionCard = styled.button`
  background: rgba(33, 38, 45, 0.6);
  border: 1px solid #30363d;
  border-radius: 12px;
  padding: 1.25rem;
  text-align: left;
  color: #f0f6fc;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(10px);
  
  &:hover {
    background: rgba(33, 38, 45, 0.8);
    border-color: #58a6ff;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  }
  
  .question {
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: #58a6ff;
  }
  
  .description {
    font-size: 0.85rem;
    color: #7d8590;
    line-height: 1.4;
  }
`;

const ChatOnly = () => {
  const { loading, error, chatWithAI } = useApi();
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const chatAreaRef = useRef(null);
  const inputRef = useRef(null);

  const suggestedQuestions = [
    {
      question: "What's the current status of my blockchain node?",
      description: "Get a comprehensive overview of your node's health, sync status, and performance metrics"
    },
    {
      question: "Are there any critical issues I should address?",
      description: "Check for potential problems, warnings, or maintenance tasks that need attention"
    },
    {
      question: "How is my node's connectivity and performance?",
      description: "Analyze peer connections, network performance, and overall node efficiency"
    },
    {
      question: "What maintenance should I perform on my node?",
      description: "Get personalized recommendations for optimal node operation and upkeep"
    }
  ];

  useEffect(() => {
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
        <Logo>
          <img 
            src="/image.png" 
            alt="Cintara" 
            style={{ width: '20px', height: '20px' }}
            onError={(e) => {
              e.target.style.display = 'none';
              e.target.nextSibling.style.display = 'flex';
            }}
          />
          <MessageCircle style={{ display: 'none' }} />
        </Logo>
        <TitleContainer>
          <Title>Cintara AI Assistant (ChatOnly Mode)</Title>
          <Subtitle>Intelligent blockchain node management and support</Subtitle>
        </TitleContainer>
      </Header>

      <ChatArea ref={chatAreaRef}>
        {messages.length === 0 && !sending ? (
          <EmptyState>
            <WelcomeIcon>
              <MessageCircle />
            </WelcomeIcon>
            <WelcomeText>
              <h2>Welcome to Cintara AI</h2>
              <p>Your intelligent assistant for blockchain node management, diagnostics, and support</p>
            </WelcomeText>
            
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
                <MessageContent>
                  <MessageBubble 
                    isUser={message.isUser}
                    style={message.isError ? { 
                      background: 'rgba(127, 29, 29, 0.8)', 
                      borderColor: '#f87171' 
                    } : {}}
                  >
                    {message.text}
                  </MessageBubble>
                  <MessageTime isUser={message.isUser}>
                    {message.timestamp.toLocaleTimeString()}
                    {message.latency && ` • ${message.latency}ms`}
                  </MessageTime>
                </MessageContent>
              </Message>
            ))}
            
            {sending && (
              <LoadingMessage>
                <Loader size={16} className="spinner" />
                AI is analyzing and preparing response...
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
            placeholder="Ask me anything about your Cintara blockchain node..."
            disabled={sending}
          />
          <SendButton 
            onClick={handleSend}
            disabled={!input.trim() || sending}
          >
            {sending ? <Loader className="spinner" /> : <Send />}
          </SendButton>
        </InputContainer>
      </InputArea>
    </Container>
  );
};

export default ChatOnly;