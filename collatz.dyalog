:Namespace Collatz

    ⎕IO←1
    DRC←⍬
    CRLF←⎕UCS 13 10
    MaxN←1000000
    MaxBatch←500

    Trajectory←{⍵=1:,1 ⋄ ⍵,∇⊃(2|⍵)⌽(⍵÷2)(1+3×⍵)}

    ∇ Start port;z;wait;obj;evt;data
      IndexHTML←⊃⎕NGET '/app/index.html' 1
      'Conga' ⎕CY 'conga'
      DRC←Conga.Init ''
      z←DRC.Srv '' '' port 'HTTP'
      :If 0≠⊃z ⋄ ⎕←'Failed to start: ' z ⋄ →0 ⋄ :EndIf
      ⎕←'Collatz API listening on port ',⍕port

      :Repeat
          :Trap 0
              wait←DRC.Wait '' 5000
              :If 0=⊃wait
                  obj←2⊃wait
                  evt←3⊃wait
                  ⍝ ⎕←evt,' on ',obj
                  :If evt≡'HTTPHeader'
                      obj HandleRequest 4⊃wait
                  :EndIf
              :EndIf
          :Else
              ⎕←'Loop error: ',⎕DMX.(EM,' ',Message)
          :EndTrap
      :EndRepeat
    ∇

    ∇ obj HandleRequest raw;tokens;method;path;query;params
      tokens←' '(≠⊆⊢)⊃CRLF{(~⍺⍷⍵)⊆⍵}raw
      method←⊃tokens
      (path query)←Split 2⊃tokens
      ⎕←method,' ',path

      :If ~method≡'GET'
          obj Respond 405 'application/json' '{"error":"Method not allowed"}'
          →0
      :EndIf

      :Trap 0
          :Select path
          :Case '/trajectory'
              params←ParseQuery query
              obj Respond HandleTrajectory params
          :Case '/batch'
              params←ParseQuery query
              obj Respond HandleBatch params
          :CaseList (,'/') '/index.html'
              obj Respond 200 'text/html; charset=utf-8' (∊IndexHTML,¨⎕UCS 10)
          :Else
              obj Respond 404 'application/json' '{"error":"Not found"}'
          :EndSelect
      :Else
          ⎕←'Error: ',⎕DMX.(EM,' ',Message)
          obj Respond 500 'application/json' '{"error":"Internal server error"}'
      :EndTrap
    ∇

    ∇ r←HandleTrajectory params;n;seq;ns;ok
      (ok n)←GetNum params 'n'
      :If ~ok
          r←400 'application/json' '{"error":"Missing or invalid n"}'
          →0
      :EndIf
      :If (n<1)∨n>MaxN
          r←400 'application/json' '{"error":"n must be 1-',(⍕MaxN),'"}'
          →0
      :EndIf
      seq←Trajectory n
      ns←⎕NS ''
      ns.start←n
      ns.steps←(≢seq)-1
      ns.peak←⌈/seq
      ns.sequence←seq
      r←200 'application/json' (⎕JSON ns)
    ∇

    ∇ r←HandleBatch params;from;to;rng;results;ns;okf;okt
      (okf from)←GetNum params 'from'
      (okt to)←GetNum params 'to'
      :If ~okf∧okt
          r←400 'application/json' '{"error":"Missing or invalid from/to"}'
          →0
      :EndIf
      :If (from<1)∨(to<from)∨(to>MaxN)
          r←400 'application/json' '{"error":"Invalid range"}'
          →0
      :EndIf
      :If MaxBatch<(to-from)+1
          r←400 'application/json' '{"error":"Range limited to ',(⍕MaxBatch),' numbers"}'
          →0
      :EndIf
      rng←(from-1)+⍳(to-from)+1
      results←{
          seq←Trajectory ⍵
          ns←⎕NS ''
          ns.start←⍵
          ns.steps←(≢seq)-1
          ns.peak←⌈/seq
          ns
      }¨rng
      r←200 'application/json' (⎕JSON results)
    ∇

    ⍝ --- utils ---

    ∇ r←Split url;qpos
      qpos←url⍳'?'
      :If qpos>≢url ⋄ r←url '' ⋄ :Else ⋄ r←((qpos-1)↑url)(qpos↓url) ⋄ :EndIf
    ∇

    ∇ params←ParseQuery qs;pairs;kv
      :If 0=≢qs ⋄ params←0 2⍴'' ⋄ →0 ⋄ :EndIf
      pairs←('&'≠qs)⊆qs
      kv←{'='∊⍵:(⍵↑⍨¯1+⍵⍳'=')(⍵↓⍨⍵⍳'=') ⋄ ⍵ ''}¨pairs
      params←↑kv
    ∇

    ∇ r←GetNum(params key);row;txt;mask;vals
      r←0 0
      :If 0=≢params ⋄ →0 ⋄ :EndIf
      row←(params[;1])⍳⊂,key
      :If row>≢params ⋄ →0 ⋄ :EndIf
      txt←⊃params[row;2]
      (mask vals)←⎕VFI txt
      :If 0=≢mask ⋄ →0 ⋄ :EndIf
      :If ⊃mask ⋄ r←1(⌊⊃vals) ⋄ :EndIf
    ∇

    ∇ obj Respond(status ct body);hdr;reason;bytes
      reason←(200 400 404 405 500⍳status)⊃'OK' 'Bad Request' 'Not Found' 'Method Not Allowed' 'Internal Server Error' 'Unknown'
      bytes←'UTF-8'⎕UCS body
      hdr←'HTTP/1.1 ',(⍕status),' ',reason,CRLF
      hdr,←'Content-Type: ',ct,CRLF
      hdr,←'Content-Length: ',(⍕≢bytes),CRLF
      hdr,←'Access-Control-Allow-Origin: *',CRLF
      hdr,←'Connection: close',CRLF
      hdr,←CRLF
      {}DRC.Send obj (('UTF-8'⎕UCS hdr),bytes)
    ∇

    ∇ Run
      Start 8080
    ∇

:EndNamespace
