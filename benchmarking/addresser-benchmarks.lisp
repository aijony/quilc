(in-package :cl-quil-benchmarking)

(defun initial-rewiring (program chip)
  (quil::prog-initial-rewiring
   program
   chip
   :type (quil::prog-initial-rewiring-heuristic program chip)))

(defun make-addresser-state (program chip)
  "Build an addresser state object of type *DEFAULT-ADDRESSER-STATE-CLASS* for the given CHIP specification and PROGRAM."
  (make-instance
   quil::*default-addresser-state-class*
   :chip-spec chip
   :initial-rewiring (initial-rewiring program chip)))

(defun do-addresser-benchmark-qft (qubits chip)
  "Run a QFT program on the given QUBITS and CHIP. Returns the time spent in the addresser."
  (let* ((program (qvm-examples::qft-circuit qubits))
         (state (make-addresser-state program chip)))
    (with-timing (1)
      (quil::do-greedy-addressing
        state
        (coerce (quil:parsed-program-executable-code program) 'list)
        :initial-rewiring (initial-rewiring program chip)
        :use-free-swaps t))))

(defun run-addresser-benchmarks-qft (chip max-qubits &key (min-qubits 1) (step 1) (runs 1)
                                                       setup-fn
                                                       completion-fn)
  "Run the QFT benchmarks against the addresser using CHIP, running from MIN-QUBITS to MAX-QUBITS in steps of size STEP. SETUP-FN is called before any benchmarks run. COMPLETION-FN runs after every benchmark (useful for streaming results to a file)."
  (when setup-fn
    (funcall setup-fn))
  (loop :for i :from min-qubits :upto max-qubits :by step
        :append (loop :repeat runs
                      :for avg := (do-addresser-benchmark-qft (a:iota i) chip)
                      :when completion-fn :do
                        (funcall completion-fn i avg)
                      :collect (cons i avg))
        :do (format t "~a of ~a~%" i max-qubits)))

;; These separate existed to determine if the addresser was sensitive
;; to the size of the chip, rather than just the size of the program.
(defun addresser-benchmark-qft-wilson ()
  (let ((wilson (build-tiled-octagon 4 4))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-wilson.txt")))
    (run-addresser-benchmarks-qft wilson 32
                                  :min-qubits 2
                                  :runs 10
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-qft-1x5 ()
  (let ((1x5 (build-tiled-octagon 5 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-1x5.txt")))
    (run-addresser-benchmarks-qft 1x5 (* 5 8)
                                  :min-qubits 2
                                  :runs 10
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-qft-2x5 ()
  (let ((1x5 (build-tiled-octagon 10 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-2x5.txt")))
    (run-addresser-benchmarks-qft 1x5 (* 10 8)
                                  :min-qubits 2
                                  :runs 10
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-qft-denali ()
  (let ((1x5 (build-tiled-octagon 20 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-denali.txt")))
    (run-addresser-benchmarks-qft 1x5 (* 5 20)
                                  :min-qubits 2
                                  :runs 1
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun bit-reversal-program (qubits)
  (let ((program (make-instance 'quil:parsed-program)))
    (setf (quil:parsed-program-executable-code program)
          (coerce (qvm-examples:bit-reversal-circuit qubits) 'vector))
    program))

(defun do-addresser-benchmark-bit-reversal (qubits chip)
  "Run a BIT-REVERSAL program on the given QUBITS and CHIP. Returns the time spent in the addresser."
  (let* ((program (bit-reversal-program qubits))
         (state (make-addresser-state program chip)))
    (with-timing (1)
      (quil::do-greedy-addressing
        state
        (coerce (quil:parsed-program-executable-code program) 'list)
        :initial-rewiring (initial-rewiring program chip)
        :use-free-swaps t))))

(defun run-addresser-benchmarks-bit-reversal (chip max-qubits &key (min-qubits 1) (step 1) (runs 1)
                                                                setup-fn
                                                                completion-fn)
  "Run the BIT-REVERSAL benchmarks against the addresser using CHIP, running from MIN-QUBITS to MAX-QUBITS in steps of size STEP. SETUP-FN is called before any benchmarks run. COMPLETION-FN runs after every benchmark (useful for streaming results to a file)."
  (when setup-fn
    (funcall setup-fn))
  (loop :for i :from min-qubits :upto max-qubits :by step
        :append (loop :repeat runs
                      :for avg := (do-addresser-benchmark-bit-reversal (a:iota i) chip)
                      :when completion-fn :do
                        (funcall completion-fn i avg)
                      :collect (cons i avg))
        :do (format t "~a of ~a~%" i max-qubits)))

;; These separate existed to determine if the addresser was sensitive
;; to the size of the chip, rather than just the size of the program.
(defun addresser-benchmark-bit-reversal-wilson ()
  (let ((wilson (build-tiled-octagon 4 4))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-bit-reversal-wilson.txt")))
    (run-addresser-benchmarks-bit-reversal wilson 32
                                           :min-qubits 2
                                           :runs 10
                                           :setup-fn (lambda () (confirm-clear-file output))
                                           :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-bit-reversal-1x5 ()
  (let ((1x5 (build-tiled-octagon 5 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-bit-reversal-1x5.txt")))
    (run-addresser-benchmarks-bit-reversal 1x5 (* 5 8)
                                           :min-qubits 2
                                           :runs 10
                                           :setup-fn (lambda () (confirm-clear-file output))
                                           :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-bit-reversal-6oct-5wid ()
  (let ((2x5 (build-tiled-octagon 6 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-bit-reversal-6oct-5wid.txt")))
    (run-addresser-benchmarks-bit-reversal 2x5 (* 6 8)
                                           :min-qubits 2
                                           :runs 10
                                           :setup-fn (lambda () (confirm-clear-file output))
                                           :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-bit-reversal-2x5 ()
  (let ((2x5 (build-tiled-octagon 10 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-bit-reversal-2x5.txt")))
    (run-addresser-benchmarks-bit-reversal 2x5 (* 10 8)
                                           :min-qubits 2
                                           :runs 2
                                           :setup-fn (lambda () (confirm-clear-file output))
                                           :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-bit-reversal-denali ()
  (let ((denali (build-tiled-octagon 20 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-bit-reversal-denali.txt")))
    (run-addresser-benchmarks-bit-reversal denali (* 5 20)
                                           :min-qubits 2
                                           :runs 1
                                           :setup-fn (lambda () (confirm-clear-file output))
                                           :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))



(defun do-addresser-benchmark-xeb (layers chip)
  "Run a XEB program on the given QUBITS and CHIP. Returns the time spent in the addresser."
  (let* ((program (xeb-program layers chip))
         (state (make-addresser-state program chip)))
    (with-timing (1)
      (quil::do-greedy-addressing
        state
        (coerce (quil:parsed-program-executable-code program) 'list)
        :initial-rewiring (initial-rewiring program chip)
        :use-free-swaps t))))

(defun run-addresser-benchmarks-xeb (chip max-layers &key (min-layers 1) (step 1) (runs 1) setup-fn completion-fn)
  "Run the XEB benchmarks against the addresser using CHIP, running from MIN-QUBITS to MAX-QUBITS in steps of size STEP. SETUP-FN is called before any benchmarks run. COMPLETION-FN runs after every benchmark (useful for streaming results to a file)."
  (when setup-fn
    (funcall setup-fn))
  (loop :for i :from min-layers :upto max-layers :by step
        :do (format t "~a of ~a~%" i max-layers)
        :append (loop :repeat runs
                      :for j := 1 :then (1+ j)
                      :for avg := (do-addresser-benchmark-xeb i chip)
                      :do (format t "    iter ~a of ~a: ~f~%" j runs avg)
                      :when completion-fn :do
                        (funcall completion-fn i avg)
                      :collect (cons i avg))))

(defun addresser-benchmark-xeb-wilson ()
  (let ((wilson (build-tiled-octagon 4 4))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-xeb-wilson.txt")))
    (run-addresser-benchmarks-xeb wilson 10
                                  :min-layers 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-xeb-1x5 ()
  (let ((1x5 (build-tiled-octagon 5 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-xeb-1x5.txt")))
    (run-addresser-benchmarks-xeb 1x5 10
                                  :min-layers 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-xeb-6oct-5wid ()
  (let ((6oct-5wid (build-tiled-octagon 6 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-xeb-6oct-5wid.txt")))
    (run-addresser-benchmarks-xeb 6oct-5wid 10
                                  :min-layers 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-xeb-2x5 ()
  (let ((2x5 (build-tiled-octagon 10 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-xeb-2x5.txt")))
    (run-addresser-benchmarks-xeb 2x5 10
                                  :min-layers 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-xeb-denali ()
  (let ((denali (build-tiled-octagon 20 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-xeb-denali.txt")))
    ;; This is hella slow, so don't do more than 3 layers.
    (run-addresser-benchmarks-xeb denali 5
                                  :min-layers 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun do-addresser-benchmark-xeb-alt (layers chip)
  "Run a XEB program on the given QUBITS and CHIP. Returns the time spent in the addresser."
  (let* ((program (xeb-program layers chip :use-1q-layers nil))
         (state (make-addresser-state program chip)))
    (with-timing (1)
      (quil::do-greedy-addressing
        state
        (coerce (quil:parsed-program-executable-code program) 'list)
        :initial-rewiring (initial-rewiring program chip)
        :use-free-swaps t))))

(defun run-addresser-benchmarks-xeb-alt (chip max-layers &key (min-layers 1) (step 1) (runs 1) setup-fn completion-fn)
  "Run the XEB benchmarks against the addresser using CHIP, running from MIN-QUBITS to MAX-QUBITS in steps of size STEP. SETUP-FN is called before any benchmarks run. COMPLETION-FN runs after every benchmark (useful for streaming results to a file)."
  (when setup-fn
    (funcall setup-fn))
  (loop :for i :from min-layers :upto max-layers :by step
        :do (format t "~a of ~a~%" i max-layers)
        :append (loop :repeat runs
                      :for j := 1 :then (1+ j)
                      :for avg := (do-addresser-benchmark-xeb-alt i chip)
                      :do (format t "    iter ~a of ~a: ~f~%" j runs avg)
                      :when completion-fn :do
                        (funcall completion-fn i avg)
                      :collect (cons i avg))))

(defun addresser-benchmark-xeb-denali-alt ()
  (let ((denali (build-tiled-octagon 20 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-xeb-denali-alt.txt")))
    (run-addresser-benchmarks-xeb-alt denali 10
                                      :min-layers 2
                                      :runs 5
                                      :setup-fn (lambda () (confirm-clear-file output))
                                      :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))









(defun do-addresser-benchmark-qaoa (n-qubits chip)
  "Run a QAOA program on the given QUBITS and CHIP. Returns the time spent in the addresser."
  (let* ((program (generate-random-qaoa-program n-qubits))
         (state (make-addresser-state program chip)))
    (with-timing (1)
      (quil::do-greedy-addressing
        state
        (coerce (quil:parsed-program-executable-code program) 'list)
        :initial-rewiring (initial-rewiring program chip)
        :use-free-swaps t))))

(defun run-addresser-benchmarks-qaoa (chip max-qubis &key (min-qubits 1) (step 1) (runs 1) setup-fn completion-fn)
  "Run the XEB benchmarks against the addresser using CHIP, running from MIN-QUBITS to MAX-QUBITS in steps of size STEP. SETUP-FN is called before any benchmarks run. COMPLETION-FN runs after every benchmark (useful for streaming results to a file)."
  (when setup-fn
    (funcall setup-fn))
  (loop :for i :from min-qubits :upto max-qubis :by step
        :do (format t "~a of ~a~%" i max-qubis)
        :append (loop :repeat runs
                      :for j := 1 :then (1+ j)
                      :for avg := (do-addresser-benchmark-qaoa i chip)
                      :do (format t "    iter ~a of ~a: ~f~%" j runs avg)
                      :when completion-fn :do
                        (funcall completion-fn i avg)
                      :collect (cons i avg))))

(defun addresser-benchmark-qaoa-wilson ()
  (let ((wilson (build-tiled-octagon 4 4))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-qaoa-wilson.txt")))
    (run-addresser-benchmarks-qaoa wilson (* 4 8)
                                  :min-qubits 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-qaoa-1x5 ()
  (let ((1x5 (build-tiled-octagon 5 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-qaoa-1x5.txt")))
    (run-addresser-benchmarks-qaoa 1x5 (* 5 8)
                                  :min-qubits 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-qaoa-6oct-5wid ()
  (let ((6oct-5wid (build-tiled-octagon 6 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-qaoa-6oct-5wid.txt")))
    (run-addresser-benchmarks-qaoa 6oct-5wid (* 6 8)
                                  :min-qubits 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-qaoa-2x5 ()
  (let ((2x5 (build-tiled-octagon 10 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-qaoa-2x5.txt")))
    (run-addresser-benchmarks-qaoa 2x5 (* 10 8)
                                  :min-qubits 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))

(defun addresser-benchmark-qaoa-denali ()
  (let ((denali (build-tiled-octagon 20 5))
        (output (merge-pathnames *benchmarks-results-directory* "/addresser-qaoa-denali.txt")))
    (run-addresser-benchmarks-qaoa denali (* 20 8)
                                  :min-qubits 2
                                  :runs 5
                                  :setup-fn (lambda () (confirm-clear-file output))
                                  :completion-fn (lambda (i avg) (file>> output "~D ~F~%" i avg)))))