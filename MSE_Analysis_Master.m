% Init_eeg;
%% Data Settings

PARENT_DIR = 'e:\Clouds\Dropbox\Uni\Brain\Thesis\EEG\Analysis\Data_4_Analysis\git-work-dir\'
DIR_INPUT  = [PARENT_DIR 'data\'];
LOAD_FORMAT= '*.mat';
DIR_OUTPUT = [PARENT_DIR 'output\'];
RES_FILE   = 'mse_res_sf40-120_'
TEMP_FILE  = [DIR_OUTPUT 'temp_mse_results_' datestr(now, '_yymmdd_HHMM_') '.mat'];

meg_code    = 200000;
Auto_Save  = true;
%% Analysis Parametes 
m = 2;
r = 0.2;
Phase_shuffeling = false;
r_search = false;
scl_fct = [4 7 10:2:40 43:3:70 75:5:120];

%% *  files Loading
% clear Results;

fileList = dir([DIR_INPUT LOAD_FORMAT]);
N_files = length(fileList);
disp(['Total number of datasets: ' num2str(N_files)]);
if Phase_shuffeling, pstag = 'psf'; else, pstag = 'org'; end

for i_f = 1:N_files  %* main loop over the files
  %% loading data 
  fileName  = fileList(i_f).name; disp(fileName)
  

  meg_file = fullfile(fileList(i_f).folder, fileList(i_f).name);    
  Load_MEG_w_ICA;    
  sgnl_2_Anlz = meg_signal;

  % make unique Serial Number for analysis
  switch grp_tag
  case {'NC' }, grp_code = 1000;
  case {'SCZ'}, grp_code = 2000;
  end       
  SN = SN_meg + grp_code + meg_code;
  clear meg_signal;

  
  if ~exist('Results', 'var'), Results = []; end
  row = length(Results) +1;
  Results(row).SN    = SN;       %#ok<*SAGROW>
  Results(row).SN_meg= SN_meg;
  Results(row).GTag  = grp_tag;
  Results(row).file  = fileName;
  Results(row).ps_tag= pstag; 
    
  %% ** Analysis ******** %%      
  
  [Nch, sig_len] = size(sgnl_2_Anlz);
  
  chnl2clc = 1:Nch;
  sgnl_2_Anlz = sgnl_2_Anlz(chnl2clc,:);
  
  %* Phase shuffling **********************************%
  if Phase_shuffeling     
    x = phaseran(sgnl_2_Anlz',1)';    
  else 
    x = sgnl_2_Anlz; %#ok
  end
  clear sgnl_2_Anlz;
  
  %* MSE calculation here 
  Results(row).mse= AnalyzeMSEpr (x, scl_fct, r, m);
  % Results(row).mse=  diff(scl_fct);   
  Results(row).mse(:, sum(Results(row).mse) == 0) = [];
  
  Results(row).t = toc  
  
  %*** search tolerance (r) ***************************%
  %{
    if r_search 
      for i_r = 1:length(r_arr)  %* Analyze for different r  
        r = R_arr(i_r);
        x = eeg_signal(Good_channels,:);
        Results(i_f).results(i_r).r = r; 
        Results(i_f).results(i_r).mse = AnalyzeMSEpr(x, scl_fct, r, 2);
        toc
      end
    end
  %}
  
  if Auto_Save 
    save (TEMP_FILE, 'Results');
  end     
end
 
Results = sortStruct(Results, 'SN', 1);

%%
AnlzParams.m = m;
AnlzParams.r = r;
AnlzParams.sclFct = scl_fct;
AnlzParams.phsfl = Phase_shuffeling;


fileName = [ DIR_OUTPUT datestr(now, 'yymmdd_HHMM_') RES_FILE 'all' ];

save (fileName, 'Results', 'AnlzParams');
% save ([RES_FILE typ datestr(now, '_yymmdd_HHMM_') '.mat'], 'Results');

clear i_f row x sgnl_2_Anlz shfl_sgnl;  clear SN SN_meg sig_len;
% clear DIR_INPUT DIR_OUTPUT LOAD_FORMAT N_files fileList fileName;