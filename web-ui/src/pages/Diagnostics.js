import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { useApi } from '../context/ApiContext';
import StatusCard from '../components/StatusCard';
// import JsonView from 'react18-json-view';
// import 'react18-json-view/src/style.css';
import { 
  RefreshCw, 
  AlertTriangle, 
  CheckCircle, 
  Info,
  FileText,
  Activity,
  Layers,
  Search
} from 'lucide-react';

const Container = styled.div`
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
`;

const Header = styled.div`
  display: flex;
  justify-content: between;
  align-items: center;
  margin-bottom: 2rem;
`;

const Title = styled.h1`
  font-size: 2rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0;
`;

const RefreshButton = styled.button`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: #21262d;
  border: 1px solid #30363d;
  border-radius: 6px;
  color: #f0f6fc;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-left: auto;

  &:hover {
    background: #30363d;
    border-color: #58a6ff;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  svg {
    width: 16px;
    height: 16px;
    ${props => props.spinning ? 'animation: spin 1s linear infinite;' : ''}
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
`;

const Grid = styled.div`
  display: grid;
  gap: 1.5rem;
  margin-bottom: 2rem;

  @media (min-width: 1024px) {
    grid-template-columns: 1fr 1fr;
  }
`;

const FullWidthSection = styled.div`
  grid-column: 1 / -1;
`;

const DiagnosticSection = styled.div`
  background: #161b22;
  border: 1px solid #30363d;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
`;

const SectionTitle = styled.h3`
  font-size: 1.125rem;
  font-weight: 600;
  color: #f0f6fc;
  margin: 0 0 1rem 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;

  svg {
    width: 20px;
    height: 20px;
  }
`;

const IssueList = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
`;

const IssueItem = styled.div`
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 1rem;
  background: #0d1117;
  border: 1px solid #21262d;
  border-radius: 6px;
  border-left: 4px solid ${props => {
    switch(props.severity) {
      case 'critical': return '#f85149';
      case 'warning': return '#f79c42';
      case 'info': return '#58a6ff';
      default: return '#7d8590';
    }
  }};
`;

const IssueIcon = styled.div`
  color: ${props => {
    switch(props.severity) {
      case 'critical': return '#f85149';
      case 'warning': return '#f79c42';
      case 'info': return '#58a6ff';
      default: return '#7d8590';
    }
  }};
  margin-top: 0.125rem;
`;

const IssueContent = styled.div`
  flex: 1;
`;

const IssueTitle = styled.div`
  font-weight: 600;
  color: #f0f6fc;
  margin-bottom: 0.25rem;
`;

const IssueDescription = styled.div`
  color: #8b949e;
  font-size: 0.875rem;
  line-height: 1.4;
`;

const RecommendationsList = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
`;

const RecommendationItem = styled.div`
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  padding: 0.75rem;
  background: #0d1117;
  border: 1px solid #21262d;
  border-radius: 4px;
  color: #8b949e;
  font-size: 0.875rem;
`;

const ErrorMessage = styled.div`
  background: #7f1d1d;
  border: 1px solid #f87171;
  border-radius: 6px;
  padding: 1rem;
  color: #fecaca;
  margin-bottom: 1rem;
`;

const LoadingSpinner = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 2rem;
  color: #7d8590;

  svg {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
`;

const JsonContainer = styled.pre`
  background: #0d1117;
  border: 1px solid #21262d;
  border-radius: 6px;
  padding: 1rem;
  max-height: 400px;
  overflow: auto;
  white-space: pre-wrap;
  word-wrap: break-word;
  color: #e1e4e8;
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
`;

const TabContainer = styled.div`
  display: flex;
  gap: 0.25rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #30363d;
`;

const Tab = styled.button`
  padding: 0.75rem 1rem;
  background: ${props => props.active ? '#21262d' : 'transparent'};
  border: none;
  border-bottom: 2px solid ${props => props.active ? '#58a6ff' : 'transparent'};
  color: ${props => props.active ? '#f0f6fc' : '#8b949e'};
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 0.875rem;
  font-weight: 500;

  &:hover {
    color: #f0f6fc;
    background: #21262d;
  }
`;

const BlockInput = styled.div`
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
  align-items: center;
`;

const Input = styled.input`
  background: #0d1117;
  border: 1px solid #30363d;
  border-radius: 4px;
  padding: 0.5rem;
  color: #f0f6fc;
  font-size: 0.875rem;
  width: 150px;
  
  &:focus {
    outline: none;
    border-color: #58a6ff;
  }
  
  &::placeholder {
    color: #7d8590;
  }
`;

const AnalyzeButton = styled.button`
  padding: 0.5rem 1rem;
  background: #238636;
  border: 1px solid #238636;
  border-radius: 4px;
  color: white;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 0.875rem;
  
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
`;

const Diagnostics = () => {
  const { 
    loading, 
    error,
    diagnoseNode,
    analyzeLogs,
    analyzeBlockTransactions,
    debugLLM
  } = useApi();

  const [activeTab, setActiveTab] = useState('overview');
  const [diagnosticsData, setDiagnosticsData] = useState(null);
  const [logsData, setLogsData] = useState(null);
  const [blockData, setBlockData] = useState(null);
  const [debugData, setDebugData] = useState(null);
  const [blockHeight, setBlockHeight] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  const fetchDiagnosticsData = async () => {
    setRefreshing(true);
    
    try {
      // Fetch node diagnostics
      const diagnostics = await diagnoseNode();
      setDiagnosticsData(diagnostics);

      // Fetch log analysis
      const logs = await analyzeLogs();
      setLogsData(logs);

      // Fetch debug info
      const debug = await debugLLM();
      setDebugData(debug);
    } catch (err) {
      console.error('Failed to fetch diagnostics data:', err);
    } finally {
      setRefreshing(false);
    }
  };

  const analyzeBlock = async () => {
    if (!blockHeight) return;
    
    try {
      const result = await analyzeBlockTransactions(parseInt(blockHeight));
      setBlockData(result);
    } catch (err) {
      console.error('Failed to analyze block:', err);
    }
  };

  useEffect(() => {
    fetchDiagnosticsData();
  }, []);

  const getIssueIcon = (severity) => {
    switch(severity) {
      case 'critical': return <AlertTriangle size={16} />;
      case 'warning': return <AlertTriangle size={16} />;
      case 'info': return <Info size={16} />;
      default: return <CheckCircle size={16} />;
    }
  };

  const getSeverityFromHealthScore = (healthScore) => {
    switch(healthScore?.toLowerCase()) {
      case 'critical': return 'critical';
      case 'warning': return 'warning';
      case 'good': return 'info';
      default: return 'info';
    }
  };

  if (loading && !diagnosticsData) {
    return (
      <Container>
        <LoadingSpinner>
          <RefreshCw size={24} />
          <span style={{ marginLeft: '0.5rem' }}>Loading diagnostics...</span>
        </LoadingSpinner>
      </Container>
    );
  }

  const diagnosis = diagnosticsData?.diagnosis || {};
  const logAnalysis = logsData?.log_analysis || {};

  return (
    <Container>
      <Header>
        <Title>Diagnostics</Title>
        <RefreshButton 
          onClick={fetchDiagnosticsData} 
          disabled={refreshing}
          spinning={refreshing}
        >
          <RefreshCw />
          {refreshing ? 'Refreshing...' : 'Refresh'}
        </RefreshButton>
      </Header>

      {error && (
        <ErrorMessage>
          Error: {error}
        </ErrorMessage>
      )}

      <TabContainer>
        <Tab 
          active={activeTab === 'overview'} 
          onClick={() => setActiveTab('overview')}
        >
          Overview
        </Tab>
        <Tab 
          active={activeTab === 'logs'} 
          onClick={() => setActiveTab('logs')}
        >
          Log Analysis
        </Tab>
        <Tab 
          active={activeTab === 'blocks'} 
          onClick={() => setActiveTab('blocks')}
        >
          Block Analysis
        </Tab>
        <Tab 
          active={activeTab === 'debug'} 
          onClick={() => setActiveTab('debug')}
        >
          Debug Info
        </Tab>
      </TabContainer>

      {activeTab === 'overview' && (
        <>
          <Grid>
            <StatusCard
              title="Node Health Assessment"
              status={diagnosis.health_score}
              description="AI-powered analysis of node health and performance"
              metrics={[
                { label: 'Health Score', value: diagnosis.health_score || 'unknown' },
                { label: 'Issues Found', value: diagnosis.issues?.length || 0 },
                { label: 'Recommendations', value: diagnosis.recommendations?.length || 0 },
                { label: 'Analysis Time', value: `${diagnosticsData?.latency_ms || 0}ms` }
              ]}
            />

            <StatusCard
              title="Log Health Status"
              status={logAnalysis.log_health}
              description="Analysis of recent node logs for issues and patterns"
              metrics={[
                { label: 'Log Health', value: logAnalysis.log_health || 'unknown' },
                { label: 'Logs Analyzed', value: logsData?.logs_found || 0 },
                { label: 'Issues', value: logAnalysis.issues?.length || 0 },
                { label: 'Patterns', value: logAnalysis.patterns?.length || 0 }
              ]}
            />
          </Grid>

          {diagnosis.issues && diagnosis.issues.length > 0 && (
            <DiagnosticSection>
              <SectionTitle>
                <AlertTriangle />
                Issues Identified
              </SectionTitle>
              <IssueList>
                {diagnosis.issues.map((issue, index) => (
                  <IssueItem key={index} severity={getSeverityFromHealthScore(diagnosis.health_score)}>
                    <IssueIcon severity={getSeverityFromHealthScore(diagnosis.health_score)}>
                      {getIssueIcon(getSeverityFromHealthScore(diagnosis.health_score))}
                    </IssueIcon>
                    <IssueContent>
                      <IssueTitle>{issue}</IssueTitle>
                    </IssueContent>
                  </IssueItem>
                ))}
              </IssueList>
            </DiagnosticSection>
          )}

          {diagnosis.recommendations && diagnosis.recommendations.length > 0 && (
            <DiagnosticSection>
              <SectionTitle>
                <CheckCircle />
                Recommendations
              </SectionTitle>
              <RecommendationsList>
                {diagnosis.recommendations.map((rec, index) => (
                  <RecommendationItem key={index}>
                    <CheckCircle size={14} style={{ color: '#4ade80', marginTop: '0.125rem', flexShrink: 0 }} />
                    {rec}
                  </RecommendationItem>
                ))}
              </RecommendationsList>
            </DiagnosticSection>
          )}

          {diagnosis.summary && (
            <DiagnosticSection>
              <SectionTitle>
                <Info />
                Summary
              </SectionTitle>
              <div style={{ color: '#8b949e', lineHeight: 1.5 }}>
                {diagnosis.summary}
              </div>
            </DiagnosticSection>
          )}
        </>
      )}

      {activeTab === 'logs' && (
        <FullWidthSection>
          <DiagnosticSection>
            <SectionTitle>
              <FileText />
              Log Analysis Results
            </SectionTitle>
            
            {logAnalysis.summary && (
              <div style={{ marginBottom: '1.5rem', padding: '1rem', background: '#0d1117', borderRadius: '6px', color: '#8b949e' }}>
                <strong style={{ color: '#f0f6fc' }}>Summary:</strong> {logAnalysis.summary}
              </div>
            )}

            {logAnalysis.issues && logAnalysis.issues.length > 0 && (
              <div style={{ marginBottom: '1.5rem' }}>
                <h4 style={{ color: '#f0f6fc', marginBottom: '0.5rem' }}>Issues Found:</h4>
                <IssueList>
                  {logAnalysis.issues.map((issue, index) => (
                    <IssueItem key={index} severity="warning">
                      <IssueIcon severity="warning">
                        <AlertTriangle size={16} />
                      </IssueIcon>
                      <IssueContent>
                        <IssueDescription>{issue}</IssueDescription>
                      </IssueContent>
                    </IssueItem>
                  ))}
                </IssueList>
              </div>
            )}

            {logAnalysis.patterns && logAnalysis.patterns.length > 0 && (
              <div style={{ marginBottom: '1.5rem' }}>
                <h4 style={{ color: '#f0f6fc', marginBottom: '0.5rem' }}>Patterns Observed:</h4>
                <RecommendationsList>
                  {logAnalysis.patterns.map((pattern, index) => (
                    <RecommendationItem key={index}>
                      <Activity size={14} style={{ color: '#58a6ff', marginTop: '0.125rem', flexShrink: 0 }} />
                      {pattern}
                    </RecommendationItem>
                  ))}
                </RecommendationsList>
              </div>
            )}

            {logsData?.log_sample && logsData.log_sample.length > 0 && (
              <div>
                <h4 style={{ color: '#f0f6fc', marginBottom: '0.5rem' }}>Recent Log Sample:</h4>
                <JsonContainer>
                  {JSON.stringify(logsData.log_sample, null, 2)}
                </JsonContainer>
              </div>
            )}
          </DiagnosticSection>
        </FullWidthSection>
      )}

      {activeTab === 'blocks' && (
        <FullWidthSection>
          <DiagnosticSection>
            <SectionTitle>
              <Layers />
              Block Transaction Analysis
            </SectionTitle>
            
            <BlockInput>
              <Input
                type="number"
                placeholder="Block height"
                value={blockHeight}
                onChange={(e) => setBlockHeight(e.target.value)}
              />
              <AnalyzeButton onClick={analyzeBlock} disabled={!blockHeight || loading}>
                <Search size={14} style={{ marginRight: '0.25rem' }} />
                Analyze Block
              </AnalyzeButton>
            </BlockInput>

            {blockData && (
              <div>
                <div style={{ marginBottom: '1rem', padding: '1rem', background: '#0d1117', borderRadius: '6px' }}>
                  <div style={{ color: '#f0f6fc', fontWeight: '600', marginBottom: '0.5rem' }}>
                    Block {blockData.block_height} Analysis
                  </div>
                  <div style={{ color: '#8b949e', fontSize: '0.875rem' }}>
                    {blockData.transaction_count} transactions • Assessment: {blockData.analysis?.overall_assessment || 'unknown'}
                  </div>
                </div>

                {blockData.analysis?.summary && (
                  <div style={{ marginBottom: '1.5rem', padding: '1rem', background: '#0d1117', borderRadius: '6px', color: '#8b949e' }}>
                    <strong style={{ color: '#f0f6fc' }}>Summary:</strong> {blockData.analysis.summary}
                  </div>
                )}

                {blockData.analysis?.transaction_patterns && blockData.analysis.transaction_patterns.length > 0 && (
                  <div style={{ marginBottom: '1.5rem' }}>
                    <h4 style={{ color: '#f0f6fc', marginBottom: '0.5rem' }}>Transaction Patterns:</h4>
                    <RecommendationsList>
                      {blockData.analysis.transaction_patterns.map((pattern, index) => (
                        <RecommendationItem key={index}>
                          <Activity size={14} style={{ color: '#58a6ff', marginTop: '0.125rem', flexShrink: 0 }} />
                          {pattern}
                        </RecommendationItem>
                      ))}
                    </RecommendationsList>
                  </div>
                )}

                {blockData.analysis?.security_issues && blockData.analysis.security_issues.length > 0 && (
                  <div style={{ marginBottom: '1.5rem' }}>
                    <h4 style={{ color: '#f0f6fc', marginBottom: '0.5rem' }}>Security Concerns:</h4>
                    <IssueList>
                      {blockData.analysis.security_issues.map((issue, index) => (
                        <IssueItem key={index} severity="warning">
                          <IssueIcon severity="warning">
                            <AlertTriangle size={16} />
                          </IssueIcon>
                          <IssueContent>
                            <IssueDescription>{issue}</IssueDescription>
                          </IssueContent>
                        </IssueItem>
                      ))}
                    </IssueList>
                  </div>
                )}
              </div>
            )}
          </DiagnosticSection>
        </FullWidthSection>
      )}

      {activeTab === 'debug' && (
        <FullWidthSection>
          <DiagnosticSection>
            <SectionTitle>
              <Activity />
              Debug Information
            </SectionTitle>
            
            {debugData && (
              <JsonContainer>
                {JSON.stringify(debugData, null, 2)}
              </JsonContainer>
            )}
          </DiagnosticSection>
        </FullWidthSection>
      )}
    </Container>
  );
};

export default Diagnostics;