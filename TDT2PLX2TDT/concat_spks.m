function [ d_out ] = concat_spks( d )
%COMBINE_SPKS: a tool function to combine multiple spike gizmos data for
%spikr sorting using PLX only, temporary
%   takes in the outout of TDT2mat, detects the number of variables in
%   d.snips, and concatenate them



if length(fields(d.snips))<=1
    d_out = d;
else
    name_snips = fields(d.snips);
    num_snips = length(name_snips);
    num_spks = zeros(num_snips,1);
    num_chans = zeros(num_snips,1);
    for i=1:num_snips
        num_spks(i)  = size(d.snips.(name_snips{i}).ts, 1);
        num_chans(i) = max(d.snips.(name_snips{i}).chan);
    end
    spk_total = sum(num_spks);
    spk_cumsum = cumsum(num_spks);
    chan_cumsum = cumsum(num_chans);
    
    snip_to_keep = d.snips.(name_snips{1});
    snip_to_keep.ts(spk_total, 1) = 0;
    snip_to_keep.chan(spk_total, 1) = 0;
    snip_to_keep.sortcode(spk_total, 1) = 0;
    snip_to_keep.data(spk_total, 1) = 0;
    snip_to_keep.index(spk_total) = 0;
    
    for i=2:num_snips
        index_to_change = spk_cumsum(i-1)+1:spk_cumsum(i);
        d.snips.(name_snips{1}).ts(index_to_change, :) = d.snips.(name_snips{i}).ts;
        d.snips.(name_snips{1}).data(index_to_change, :) = d.snips.(name_snips{i}).data;
        d.snips.(name_snips{1}).chan(index_to_change, :) = d.snips.(name_snips{i}).chan + chan_cumsum(i-1);
        d.snips.(name_snips{1}).sortcode(index_to_change, :) = d.snips.(name_snips{i}).sortcode;
        d.snips.(name_snips{1}).index(index_to_change) = d.snips.(name_snips{i}).index;
    end
    d_out = d;
end
    
end

