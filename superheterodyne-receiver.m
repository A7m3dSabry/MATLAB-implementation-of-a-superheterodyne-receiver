clear;
close all;
% the Signal bandwidth is used 20KHz as the sounds that the hummans can
% hear is from 0Hz to 20KHz
%% read the signal
FilePath1 = audiosShort_QuranPalestine.wav;
FilePath2 = audiosShort_BBCArabic2.wav;
[Signal1,Sample_Rate1] = ReadFile(FilePath1);
[Signal2,Sample_Rate2] = ReadFile(FilePath2);
% convert the signal to mono (the transpose to convert it to row matrix)
Signal1=GetMonoMessage(Signal1)'length(Signal1);
Signal2=GetMonoMessage(Signal2)'length(Signal2);
%% modulator
Fc=10^5;
dF=50000; %% 50 KHz
Signal1=interp(Signal1,10); %increase the samples
Signal2=interp(Signal2,10);
Sample_Rate1 =Sample_Rate1  10; %increase frequency of the sampling
Sample_Rate2 =Sample_Rate2  10;
carrier1 = GetCarrier(Fc,Sample_Rate1,length(Signal1)); %creae a carrier at FC
carrier2 = GetCarrier(Fc+dF,Sample_Rate2,length(Signal2));
x1=Signal1 .* carrier1; %Modulated Signal
x2=Signal2 .* carrier2;
subplot(2,2,1);
Plot(x1,Sample_Rate1,'r','Signal 1','Signal 1 Modualted');
subplot(2,2,2);
Plot(x2,Sample_Rate1,'b','Signal 2','Signal 2 Modualted');
channel = AddSignals(x1,x2);
subplot(2,1,2);
PlotChannel(x1,x2,Sample_Rate1,Sample_Rate2,'r','b','Signal 1', 'Signal 2','Channel');
%% RF Stage Filter
BPF_Signal1=design(fdesign.bandpass(Fc-20000-1000,Fc-20000,Fc+20000,Fc+20000+1000,80,1,80,Sample_Rate1),'equiripple');
BPF_Signal2=design(fdesign.bandpass(Fc+dF-20000-5000,Fc+dF-20000,Fc+dF+20000,Fc+dF+20000+5000,80,1,80,Sample_Rate2),'equiripple');
out1=filter(BPF_Signal1,channel); %Filtered Signal
out2=filter(BPF_Signal2,channel);
figure;
subplot(5,2,1);
Plot(out1,Sample_Rate1,'r','Signal 1','RF Filter Output Signal');
subplot(5,2,2);
Plot(out2,Sample_Rate2,'b','Signal 2','RF Filter Output Signal');
%% RF Stage Mixer
IF=25000; %intermediate Frecency
FifC1=GetCarrier(Fc+IF,Sample_Rate1,length(out1)); % create carrier at intermediate frequency + carrier frequency
FifC2=GetCarrier(Fc+dF+IF,Sample_Rate2,length(out2));
m1=out1.*FifC1;
m2=out2.*FifC2;
subplot(5,2,3);
Plot(m1,Sample_Rate1,'r','Signal 1','RF Mixer Output Signal');
subplot(5,2,4);
Plot(m2,Sample_Rate2,'b','Signal 2','RF Mixer Output Signal');
%% IF Stage Filter
BPF_IFStage1=design(fdesign.bandpass(IF-20000-1000,IF-20000,IF+20000,IF+20000+1000,80,1,80,Sample_Rate1),'equiripple');
BPF_IFStage2=design(fdesign.bandpass(IF-20000-1000,IF-20000,IF+20000,IF+20000+1000,80,1,80,Sample_Rate2),'equiripple');
out1=filter(BPF_IFStage1,m1);
out2=filter(BPF_IFStage2,m2);
subplot(5,2,5);
Plot(out1,Sample_Rate1,'r','Signal 1','IF Filter Output Signal');
subplot(5,2,6);
Plot(out2,Sample_Rate2,'b','Signal 2','IF Filter Output Signal');
%% BaseBand Stage
C1=GetCarrier(IF,Sample_Rate1,length(out1));
C2=GetCarrier(IF,Sample_Rate2,length(out2));
out1=out1 .* C1;
out2=out2 .* C2;
subplot(5,2,7);
Plot(out1,Sample_Rate1,'r','Signal 1','IF Mixer Output Signal');
subplot(5,2,8);
Plot(out2,Sample_Rate2,'b','Signal 2','IF Mixer Output Signal');
%% LPF Stage
out1=lowpass(out1,20000,Sample_Rate1); %couldn't design the LowPass using the fdesign and i found this method on internet
out2=lowpass(out2,20000,Sample_Rate2);
subplot(5,2,9);
Plot(out1,Sample_Rate1,'r','Signal 1','LPF Output Signal');
subplot(5,2,10);
Plot(out2,Sample_Rate2,'b','Signal 2','LPF Output Signal');
%% functions
function Plot(Signal,Rate,color,Legend,Title)
plot((-length(Signal)/2:length(Signal)/2 -1)*Rate/length(Signal), abs(fftshift(fft(Signal))),color);
legend(Legend);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title(Title);
end
function PlotChannel(Signal1,Signal2,Rate1,Rate2,color1,color2,Legend1,Legend2,Title)
plot((-length(Signal1)/2:length(Signal1)/2 -1)*Rate1/length(Signal1), abs(fftshift(fft(Signal1))),color1,(-length(Signal2)/2:length(Signal2)/2 -1)*Rate2/length(Signal2), abs(fftshift(fft(Signal2))),color2);
legend(Legend1,Legend2);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title(Title);
end
function [MixedSignal] = AddSignals(Signal1,Signal2)
L1=length(Signal1);
L2 = length(Signal2);
if L1>L2
Signal2=[Signal2 zeros(1,L1-L2)];
else
Signal1=[Signal1 zeros(1,L2-L1)];
end
MixedSignal = Signal1+Signal2;
end
function [carrier] = GetCarrier(Frequency,SampleRate,MessageLength)
t = 0:1/SampleRate:(MessageLength -1)/SampleRate ;
carrier = cos(2*pi*Frequency*t);
end
function [message,SampleRate] = ReadFile(FilePath)
[message,SampleRate] = audioread(FilePath);
end
function [MonoMessageAudio] = GetMonoMessage(MessageAudio)
if (size(MessageAudio,2) == 2) %% check if 2 columns which is sterio mode
MessageAudio=MessageAudio(:,1)+MessageAudio(:,2);
end
MonoMessageAudio = MessageAudio;
end
