classdef TCP < handle
    %TCP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        inputBufferSize = 30000
        outputBufferSize = 30000
        
        f_tcp
        
        host = 'localhost'
        port = 4012
        
    end
    
    methods
        function self = TCP(host, port)

            if nargin > 1
                self.host = host;
            end
            if nargin > 2
                self.port = port;
            end
            
            self.f_tcp = tcpip(self.host, self.port); 
            set(self.f_tcp, 'InputBufferSize', self.inputBufferSize); 
            set(self.f_tcp, 'OutputBufferSize', self.outputBufferSize);        
        end
        
        function open(self)
            fopen(self.f_tcp);
        end
        
        function close(self)
            fclose(self.f_tcp);
        end
        
        function delete(self)
            self.close();
        end
        
        function flush(self)
            while (get(self.f_tcp, 'BytesAvailable') > 0)
                str2double(fscanf(self.f_tcp));
            end
        end
        
        function send(self, data, is_integer)
            if is_integer
                fprintf(self.f_tcp, num2str(data));
            else
                fprintf(self.f_tcp, data);
            end
        end
        
        function data = receive(self, nBytes)
            data = [];
            if nargin == 1
                nBytes = 0;
            end
            %Block until bytes available
            while (get(self.f_tcp, 'BytesAvailable') == 0)
                %do nothing
                pause(0.001)
            end
            %Once bytes available, get them
            if nBytes == 0
                while (get(self.f_tcp, 'BytesAvailable') > 0)
                    data(end+1) = str2double(fscanf(self.f_tcp));
                end
            else
                for i = 1:nBytes
                    data(end+1) = str2double(fscanf(self.f_tcp));
                end
            end
        end
        
        function send_features_and_state(self, features, state)
            self.send(state, 1);
            self.send(features, 0);
        end
        
        function [features, state] = receive_features_and_state(self)
            state = self.receive(1);
            features = self.receive();
        end

    end
end

